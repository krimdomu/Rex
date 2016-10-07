#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::DSL::Common::task;

use strict;
use warnings;

# VERSION

use Rex -minimal;
use Rex::DSL::Common;
use Rex::Helper::Path;
use Moose::Util::TypeConstraints;
use Rex::TaskList::Store;

subtype 'TaskName',
    as 'Str',
    where { $_ =~ m/^[a-zA-Z_][a-zA-Z0-9_]*$/ };

subtype 'TaskTypeGroup',
    as 'Str',
    where { $_ eq "group" };

# create the function "is_file"
dsl "task", {

  export => 1,

  params_list => [
    name => { isa => 'TaskName', },
    code => { isa => 'CodeRef', },
  ]
  },

  sub {
      my ($task_name, $code) = @_;

      _create_task(
        task_name => $task_name,
        code => $code,
      );

      return { value => 1, };
  };

dsl "task", {

  export => 1,

  params_list => [
    name => { isa => 'TaskName', },
    server => { isa => 'Str', },
    code => { isa => 'CodeRef', },
  ]
  },

  sub {
      my ($task_name, $server, $code) = @_;

      _create_task(
        task_name => $task_name,
        code => $code,
        server => [$server],
      );

      return { value => 1, };
  };

dsl "task", {

  export => 1,

  params_list => [
    name => { isa => 'TaskName', },
    type => { isa => 'TaskTypeGroup', },
    group => { isa => 'Str', },
    code => { isa => 'CodeRef', },
  ]
  },

  sub {
      my ($task_name, $type, $group, $code) = @_;

      my @servers = Rex::Group->get_group($group);

      _create_task(
        task_name => $task_name,
        code => $code,
        servers => \@servers,
      );

      return { value => 1, };
  };

dsl "task", {

  export => 1,

  params_list => [
    name => { isa => 'TaskName', },
    type => { isa => 'TaskTypeGroup', },
    group => { isa => 'ArrayRef', },
    code => { isa => 'CodeRef', },
  ]
  },

  sub {
      my ($task_name, $type, $group, $code) = @_;

      my @servers = Rex::Group->get_group($group);

      _create_task(
        task_name => $task_name,
        code => $code,
        servers => \@servers,
      );

      return { value => 1, };
  };

sub _create_task {
  my (%opts) = @_;

  my $task_name = $opts{task_name};

  # we need to go 5 steps up the stack
  # - Rex::MultiSub::function
  #   - Moose::Meta::Method::Overridden
  #     - Rex::MultiSub
  #       - Rex::MultiSub
  #         - <real caller | Rexfile/Module>
  my ( $class, $file, @tmp ) = caller(5);

  if ( $class ne "main" && $class ne "Rex::CLI" ) {
    $task_name = $class . ":" . $task_name;
  }

  $task_name =~ s/^Rex:://;
  $task_name =~ s/::/:/g;

  my $app = Rex->instance;
  my $task_o = Rex::Task->new(
      name    => $task_name,
      code    => $opts{code},
      server  => $opts{servers},
  );

  push @{ $app->task_store->tasks }, $task_o;
}


1;

=head1 NAME

Rex::DSL::Common::task - Create a new task

=head1 DESCRIPTION

The I<task()> function is a dsl function which creates a new task.

=head1 SYNOPSIS

 task "configure_something", "server01", sub {
     # code
 };

 task "configure_something", group => "groupname", sub {
     # code
 };

 task "configure_something", group => ["groupname"], sub {
     # code
 };



=cut
