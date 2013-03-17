package Timer;
use Moose::Role;
use namespace::autoclean;

use AnyEvent;

has 'name' => (is => 'rw');
has '_alarm' => (is => 'rw');
has '_on' => (is => 'rw');

sub handler {
	my $self = shift;
	$self->_alarm(shift);
}

sub active {
    my $self = shift;
    return $self->on;
}

sub alarm {
	my $self = shift;
	$self->_on(1);
	$self->_alarm();
}

sub set { confess shift, " should have defined set!"}

1;