#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::TaskList::Parallel_ForkManager;

use strict;
use warnings;

# VERSION

use Data::Dumper;
use Rex::Logger;
use Rex::Task;
use Rex::Config;
use Rex::Interface::Executor;
use Rex::TaskList::Base;
use Rex::Report;
use Time::HiRes qw(time);

BEGIN {
  use Rex::Shared::Var;
  share qw(@SUMMARY);

  use Rex::Require;
  Parallel::ForkManager->require;
}

use base qw(Rex::TaskList::Base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

sub run {
  my ( $self, $task_name, %option ) = @_;
  my $task = $self->get_task($task_name);

  $option{params} ||= { Rex::Args->get };

  my @all_server = @{ $task->server };

  my $fm = Parallel::ForkManager->new( $self->get_thread_count($task) );

  $fm->run_on_finish(
    sub {
      my ( $pid, $exit_code ) = @_;
      Rex::Logger::debug("Fork exited: $pid -> $exit_code");
    }
  );

  for my $server (@all_server) {
    my $forked_sub = sub {
      Rex::Logger::init();
      Rex::Logger::info("Running task $task_name on $server");

      # create a task object for each $server
      my $run_task = Rex::Task->new( %{ $task->get_data } );
      my $return_value = $run_task->run(
        $server,
        in_transaction => $self->{IN_TRANSACTION},
        params         => $option{params}
      );

      Rex::Logger::debug("Destroying all cached os information");
      Rex::Logger::shutdown();

      return $return_value;
    };

    # add the worker (forked_sub) to the fork queue
    unless ( $self->{IN_TRANSACTION} ) {

      # not inside a transaction, so lets fork happyly...
      $fm->start and next;

      eval { $forked_sub->() };
      my $exit_code = $@ ? ($? || 1) : 0;
      push @SUMMARY, {
        task      => $task_name,
        server    => $server->to_s,
        exit_code => $exit_code,
      };

      $fm->finish;
    }
    else {
# inside a transaction, no little small funny kids, ... and no chance to get zombies :(
      &$forked_sub();
    }
  }

  Rex::Logger::debug("Waiting for children to finish");
  my $ret = $fm->wait_all_children;

  Rex::reconnect_lost_connections();

  return $ret;
}

sub get_exit_codes {
  my ($self) = @_;
  return map { $_->{exit_code} } @SUMMARY;
}

sub get_summary { @SUMMARY }

1;
