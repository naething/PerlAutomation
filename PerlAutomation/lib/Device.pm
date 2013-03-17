package Device;

use Moose;
use namespace::autoclean;

has 'key'   => ( is => 'rw' , default => "no_key");
has 'name'  => ( is => 'rw' , default => "no_name");
has 'room'  => ( is => 'rw' );
has 'house' => ( is => 'rw' );
has 'type'  => ( is => 'rw', default => "generic");

sub json {
    my $self = shift;
    return {id   => $self->key,
    	    name => $self->name,
    	    type => $self->type};
}

1;