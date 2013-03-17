package DimmableLight;
use Moose::Role;
use namespace::autoclean;

has 'power' => (
    is => 'rw',
    isa => 'Bool',
);

has 'level' => (
    is => 'rw',
    isa => 'Int',
);

1;
