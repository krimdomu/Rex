#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Test::Cluster::Proxy - Proxy Modul for Rex::Test::Base

=head1 DESCRIPTION

Proxy requests to Rex::Test::Base and set connection.

=head1 EXAMPLE


=cut

package Rex::Test::Cluster::Proxy;

use strict;
use warnings;

# VERSION

use Moose;

require Rex::Test::Base;

has test => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    return Rex::Test::Base->new(box => $self->box);
  },
);

has box => (
  is => 'ro',
);

has connection => (
  is => 'ro',
  writer => '_set_connection',
);

our $AUTOLOAD;

sub AUTOLOAD {
  my $self = shift or return;
  ( my $method = $AUTOLOAD ) =~ s{.*::}{};
  
  if($self->connection) {
      Rex::connect(
        cached_connection => $self->connection
      );
  }
  else {
    $self->_set_connection(
      Rex::connect(
        server => $self->box->ip,
        %{ $self->box->auth },
      )
    );
  }
  
  $self->test->$method(@_);
}

1;