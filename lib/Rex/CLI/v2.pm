#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::CLI;

use Moo;
use common::sense;
use Data::Dumper;

use MooX::Cmd;
use MooX::Options flavour => [qw( pass_through )];


use Data::Dumper;

use Rex;
use Rex::Config;
use Rex::Group;
use Rex::Batch;
use Rex::TaskList;
use Rex::Logger;
use YAML;

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

  print Dumper $args_ref;

  if($self->version) {
    $self->__version__();
  }
}

sub __run__ {
  my $self = shift;
  ref($self)->new_with_cmd;
}

sub __version__ {
  print "(R)?ex " . $Rex::VERSION . "\n";
  CORE::exit 0;
}

1;
