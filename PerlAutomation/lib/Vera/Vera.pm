#***************************************************************************#
# Micasaverde Interface
#***************************************************************************#
#
# Author: Rick Naething
# Version: 0.01
#

package Vera;

use Moose;
use namespace::autoclean;
use AnyEvent;
use AnyEvent::HTTP;
use Data::Dumper;
use JSON qw( decode_json );
use strict;
use warnings;
use Vera::VeraDevice;
use Vera::VeraDeviceFactory;
use Switch;

extends 'Device';

#***************************************************************************#
has 'ip'       => ( is => 'rw' );
has 'port'     => ( is => 'rw' );
has 'callback' => ( is => 'rw' );
has '_uidata'  => ( is => 'rw' );
has '_baseurl' => ( is => 'rw' );

#***************************************************************************#


#***************************************************************************#
# Stored info from Vera
has 'categories' => (
	is => 'ro',
	traits => [ 'Hash' ],
	isa => 'HashRef',
	default => sub { {} },
	handles => {
		get_category => 'get',
		set_category => 'set',
	},
);

has 'rooms' => (
	is => 'ro',
	traits => [ 'Hash' ],
	isa => 'HashRef',
	default => sub { {} },
	handles => {
		get_room => 'get',
		set_room => 'set',
	},
);

has 'devices' => (
	is => 'ro',
	traits => [ 'Hash' ],
	isa => 'HashRef',
	default => sub { {} },
	handles => {
		get_device => 'get',
		set_device => 'set',
	},
);

#***************************************************************************#
# Handle Commands
#***************************************************************************#
sub child_command{
	my $self     = shift;
	my $child_id = shift;
	my $cmd      = shift;

    my $sid = '';
    my $action = '';
	switch ($cmd->{'command'}){
        case 'SetArmed' {
        	$sid    = 'urn:micasaverde-com:serviceId:SecuritySensor1';
        	$action = 'SetArmed&newArmedValue=';
        }

        case 'SetLoadLevelTarget' {
        	$sid    = 'urn:upnp-org:serviceId:Dimming1';
        	$action = 'SetLoadLevelTarget&newLoadlevelTarget=';
        }

        case 'SetTarget' {
        	$sid    = 'urn:upnp-org:serviceId:SwitchPower1';
        	$action = 'SetTarget&newTargetValue=';
        }

        else {
            warn("Unknown Command" . $cmd->{'command'} . "\n");
        }
	}

	my $url = 'http://' . $self->ip . ':' . $self->	port .
	          "/data_request?id=lu_action&DeviceNum=" . $child_id .
              "&serviceId=" . $sid . "&action=" . $action . $cmd->{'payload'};

	http_request GET => $url, cb => sub {};
	print "\n\n\n\n";
	print "Fetching " . $url . "\n";
	print "\n\n\n\n";
}


#***************************************************************************#
# Rendering information
sub template{
	my $self = shift;
	return 'vera.tt' => { 'device' => 'vera',
	                      'rooms'  => $self->rooms,
	                      'devices' => $self->devices };
};

#***************************************************************************#
# Connection Functions
#***************************************************************************#
sub fetch_initial_url {
	my $self = shift;
    http_request GET => $self->_baseurl,
                 cb => sub { $self->parse_initial_load($_[0]); };
    print "Fetching " . $self->_baseurl . "\n";
}

sub fetch_next_url {
	my $self = shift;
	my $json = shift;
	my $url = $self->_baseurl . "&loadtime="    . $json->{'loadtime'}
                              . "&dataversion=" . $json->{'dataversion'}
                              . "&timeout=60&minimumdelay=2000";
	http_request GET => $url,
                 cb => sub { $self->parse_upload_load($_[0]); };
    print "Fetching " . $url . "\n";
}

sub parse_initial_load {
	print "HERE";
    my $self = shift;
    my $json = shift;
    my $decoded_json = decode_json( $json );
    $self->create_devices($decoded_json);
    $self->fetch_next_url($decoded_json);
}

sub parse_upload_load {
   my $self = shift;
   my $json = shift;
   my $decoded_json = 	decode_json( $json );
   foreach my $d (@{$decoded_json->{'devices'}}){
       $self->devices->{$d->{'id'}}->update($d);
   }
   $self->fetch_next_url($decoded_json);
}

#***************************************************************************#
# JSON Parsing
#***************************************************************************#
sub create_devices {
    my $self = shift;
    my $decoded_json = shift;

    # Read in Categoryinformation (from JSON -> Vera Class)
    #foreach my $j ('categories', 'rooms'){
    if (exists $decoded_json->{'categories'}) {
    	foreach my $c (@{$decoded_json->{'categories'}}) {
    		$self->{'categories'}->{$c->{'id'}}=$c->{'name'};
    	}
    }
	#}

	# Read in Room information
	$self->{'rooms'}->{'0'} = {'name' => 'No Room'};
    if (exists $decoded_json->{'rooms'}) {
    	foreach my $c (@{$decoded_json->{'rooms'}}) {
    		# Add rooms to Vera
    		$self->{'rooms'}->{$c->{'id'}}= {'name' => $c->{'name'}};

    		# Add room names to house, if needed
    	    $self->house->set_room($c->{'name'}, [])
    	    unless ($self->house->get_room($c->{'name'}));
    	}
    }

    # Fill in Devices
    # Use proper constructor that is unique per Category
    if (exists $decoded_json->{'devices'}) {	
	    foreach my $d (@{$decoded_json->{'devices'}}) {

	    	# Create device
	    	my $type = $self->categories->{$d->{'category'}};
	    	my $new_device = VeraDeviceFactory($type, $d);
	    	$self->devices->{$d->{'id'}} = $new_device;

	    	# Set id prefix / parent on device
	    	$new_device->key($self->key . $d->{'id'});
	    	$new_device->vera($self);

	    	# Add to Vera objects
	    	push @{$self->devices->{$d->{'id'}}->callbacks}, $self->callback;
	        push @{$self->rooms->{$d->{'room'}}->{'devices'}}, $d->{id};

	        # Add to house object
	        $self->house->set_device($new_device->key, $new_device);
	        my $room_name = $self->{'rooms'}->{$d->{'room'}}->{'name'};
	        my $room = $self->house->get_room($room_name);
          	push @{$room}, $new_device;
	    }
	}
}

#***************************************************************************#
# Connection Functions
#***************************************************************************#

sub connect{
	my $self = shift;
	$self->_baseurl('http://' . $self->ip . ':' . $self->	port .
	                '/data_request?id=lu_sdata');
	$self->fetch_initial_url();
}

1;