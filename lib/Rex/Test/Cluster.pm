#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Test::Cluster - Cluster Test Module

=head1 DESCRIPTION

This is a basic cluster test module.

=head1 EXAMPLE


=cut

package Rex::Test::Cluster;

use strict;
use warnings;

# VERSION

use Moose;
use Rex::Test::Cluster::Proxy;

require Rex::Commands::Box;
require Rex::Test::Base;

has cluster_def => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has vms => (
  is => 'ro',
  isa => 'HashRef',
  writer => '_set_vms',
);

sub initialize {
  my ($self) = @_;
  Rex::Commands::Box->load_init_file( $self->cluster_def );
  $self->_set_vms(Rex::Commands::Box::boxes("init"));
}

sub vm {
  my ($self, $name) = @_;
  my $proxy = Rex::Test::Cluster::Proxy->new(box => $self->vms->{$name});
  return $proxy;
}

sub finish {
  my ($self) = @_;

  my $tb = Rex::Test::Base->builder;
  $tb->done_testing();
  $tb->is_passing()
    ? print "PASS\n"
    : print "FAIL\n";
  $tb->reset();
}

1;