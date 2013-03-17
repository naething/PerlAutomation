package House;
use Moose;
use namespace::autoclean;

has 'devices' => (
	is => 'rw',
	traits => [ 'Hash' ],
	isa => 'HashRef',
	default => sub { {} },
	handles => {
		get_device => 'get',
		set_device => 'set',
	},
);

has 'timers' => (
	is => 'rw',
	traits => [ 'Hash' ],
	isa => 'HashRef',
	default => sub { {} },
	handles => {
		get_timer => 'get',
		set_timer => 'set',
	},
);

has 'rooms' => (
	is => 'rw',
	traits => [ 'Hash' ],
	isa => 'HashRef',
	default => sub { {} },
	handles => {
		get_room => 'get',
		set_room => 'set',
	},
);

1;