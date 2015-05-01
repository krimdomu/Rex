#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::CLI::Command;

use Moo::Role;

sub app {
  my $self = shift;
  my ($app) = grep { ref $_ eq "Rex::CLI" } @{ $self->command_chain };
  $app ||= $self;

  return $app;
}

before execute => sub {
  my ($self) = @_;
  $self->app->init();
};

1;
