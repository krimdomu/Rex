#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::Cmd;

use Moo;
use common::sense;
use Data::Dumper;

use MooX::Cmd;
use MooX::Options;

use Rex::CLI;

use Data::Dumper;

option debug => (
  is => 'ro',
  doc => 'Switch on debug output.',
  default => 0,
);

option version => (
  is => 'ro',
  doc => 'Show the version of Rex',
  short => 'v',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  if($self->version) {
    Rex::CLI->__version__();
  }
}

sub __run__ {
  my $self = shift;
  ref($self)->new_with_cmd;
}

1;
