package SimpleTimer;
use Moose;
use namespace::autoclean;

with 'Timer';

has '_t' => (is => 'rw');

sub set {
    my $self = shift;
    my $time = shift;
    my $delay = $time - AnyEvent->now;
    $self->_t( AnyEvent->timer( after=> $delay, cb=> $self->alarm));
}

no Moose;

1;