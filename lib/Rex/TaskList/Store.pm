package Rex::TaskList::Store;

use MooseX::Singleton;

has 'tasks' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
);



1;