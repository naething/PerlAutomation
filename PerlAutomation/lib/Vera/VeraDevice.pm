#-----------------------------------------------------------------------------
# Generic Device:

package VeraDevice;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Template;

extends 'Device';

use constant { true => 1, false => 0 };

has 'type'        => ( is => 'ro', default => 'generic');

# Set by Vera.pm:
has 'key'   => ( is => 'rw');
has 'vera'  => ( is => 'rw');

# These are all from the Vera JSON:
has 'id'          => ( is => 'ro');
has 'altid'       => ( is => 'ro');
has 'category'    => ( is => 'ro');
has 'name'        => ( is => 'ro');
has 'parent'      => ( is => 'ro');
has 'room'        => ( is => 'ro');
has 'subcategory' => ( is => 'ro');
has 'status'      => ( is => 'ro');
has 'comment'     => ( is => 'ro');
has 'state'       => ( is => 'ro');

# not passed in:
has 'watched'     => ( is => 'ro', isa => 'ArrayRef', default => sub { [] });
has 'callbacks'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] });

sub json {
    my $self = shift;
    my %hash;
    $hash{id}   = $self->key;
    $hash{name} = $self->name;
    $hash{type} = $self->type;
    foreach my $watchedVar (@{$self->watched}){
        $hash{$watchedVar} = $self->{$watchedVar};
    }
    return {%hash};
}
 
sub command {
    my $self = shift;
    my $cmd  = shift;
    $self->vera->child_command($self->id, $cmd);
}

sub tostring {
    my $self = shift;
    return $self->name();
}

sub getStateTuple {
    my $self = shift;
    my @array = ();
    return @array; #empty
}

sub update {
    my $self = shift;
    my $d    = shift;
    my $changed = false;

    # see if a monitored variable changed
    foreach my $watchedVar (@{$self->watched}){
        if (exists($d->{$watchedVar})) {
            if ($self->{$watchedVar} != $d->{$watchedVar}){
                $changed = true;
            }
        }
    }
             
    my $oldState = $self->getStateTuple();
                 
    foreach my $k (keys(%{$d})){
        if (exists($self->{$k})) {
            $self->{$k} = $d->{$k};
        } else {
            print($self->name . ' does not have an attribute ' . $k . "\n");
        }
    }

    if ($changed){
        foreach my $c (@{$self->callbacks}){
            $c->($self, ['TRANSITION', $oldState, $self->getStateTuple()]);
        }
    }
}

#----------------------------------------------------------------------------- 
# Category #2: Dimmable Lights 
package VeraDimmableLight;
use Moose;
use namespace::autoclean;
extends 'VeraDevice';

has 'type' => ( is => 'ro', default => 'dimmableLight');

has 'level' => ( is => 'ro' );
has 'watched' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { ['status','level'] }
);

sub tostring {
    my $self = shift;
    my @state = $self->getStateTuple();
    return sprintf('%s.%s.%.0f', $self->name, $state[0], $state[1]);
}

sub getStateTuple {
    my $self = shift;
    my $onOff = ($self->status eq '0') ? 'OFF' : 'ON';
    return [$onOff, ($self->level + 0)];
}

#----------------------------------------------------------------------------- 
# Category #3: Switch
package VeraSwitch;
use Moose;
use namespace::autoclean;
extends 'VeraDevice';

has 'type' => ( is => 'ro', default => 'binarySwitch');

has 'level' => ( is => 'ro' );
has 'watched' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { ['status'] }
);

sub tostring {
    my $self = shift;
    my @state = $self->getStateTuple();
    return sprintf('%s.%s.%.0f', $self->name, $state[0], $state[1]);
}

sub getStateTuple {
    my $self = shift;
    my $onOff = ($self->status eq '0') ? 'OFF' : 'ON';
    return [$onOff];
}

#----------------------------------------------------------------------------- 
# Category #4: Security Sensor

package VeraSensor;
use Moose;
use namespace::autoclean;
extends 'VeraDevice';

has 'type' => ( is => 'ro', default => 'securitySensor');

has 'armed'   => ( is => 'ro' );
has 'tripped' => ( is => 'ro' );
has 'watched' => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { ['armed', 'tripped'] }
);

sub tostring {
    my $self = shift;
    my @state = $self->getStateTuple();
    return sprintf('%s.%s.%s', $self->name, $state[0], $state[1]);
}

sub getStateTuple {
    my $self = shift;
    my $trip = ($self->tripped eq '0') ? 'CLEAR' : 'TRIPPED';
    my $arm  = ($self->armed   eq '1') ? 'ARMED' : 'NOT_ARMED';
    return [$trip, $arm];
}

1;