#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Resource::firewall::Provider::base;

use strict;
use warnings;

# VERSION

use Moose;

use Rex::Helper::Run;

extends qw(Rex::Resource::Provider);

sub test {
  my ($self) = @_;

  my $mod = $self->name;

  # nothing todo
  return 1;

  # we have to do something
  return 0;
}

1;
