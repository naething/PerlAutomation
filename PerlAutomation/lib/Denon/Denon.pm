#***************************************************************************#
# Denon 3808ci Interface
#***************************************************************************#
#
# Author: Rick Naething
# Version: 0.01
#

package Denon;

use IO::Socket;
use Moose;
use namespace::autoclean;
use AnyEvent;
use AnyEvent::Handle;
use Data::Dumper;

extends 'Device';

#with 'SimpleVolume';

has 'type' => ( is => 'ro', default => 'binarySwitch');

#***************************************************************************#
# properties that deal with the connection
has 'ip'   => ( is => 'rw' );
has 'port' => ( is => 'rw' );
has '_fh'   => ( is => 'rw' );
has '_handle' => ( is => 'rw' );

#***************************************************************************#
# State Information about the Denon
has '_mute_state' => ( is => 'ro' );

#***************************************************************************#
# Rendering information
sub template{
	my @zones = ("One","Two","Three");
	my @sources = ('TUNER','PHONO','CD','DVD','HDP','TV/CBL',
	               'SAT','VCR','DVR','V.AUX','NET/USB','XM');
	return 'denon.tt' => { 'device' => 'denon', 'zones' => \@zones, => 'sources' => \@sources };
};

sub handle_command{
	my $self = shift;
	my $command = shift;
	print "COMMAND: $command\n";
}

#***************************************************************************#
# Simple Volume Role
#***************************************************************************#

sub receive_data {
	my $self = shift;
	warn Dumper($self->_handle->rbuf);
	$self->_handle->rbuf="";
};

sub down {
	my $self = shift;
	warn Dumper($self->_fh);
    print { $self->_fh } "MVDN\r";
}

sub up {
	my $self = shift;
	warn Dumper($self->_fh);
    print { $self->_fh } "MVUP\r";
}

sub toggle_mute{}


#***************************************************************************#
# Connection Functions
#***************************************************************************#
sub connect {
	my $self = shift;
	
	# Connect to Denon.
	$self->_fh ( IO::Socket::INET->new (Proto => "tcp",
	                                    PeerAddr => $self->ip,
	                                    PeerPort => $self->port) )
		or warn "can't connect\n";
	
	# now construct AnyEvent::Handler to watch the port for incoming data. We will still use
	# the fh to SEND data.
	$self->_handle ( AnyEvent::Handle->new (
		fh => ($self->_fh),
		on_connect => sub { warn('connected') },
		on_eof => sub {warn "disconnected";} )
	);
	
	# Figure out 
	$self->_handle->on_read( sub{  $self->receive_data } );

	# Add room names to house, if needed
    $self->house->set_room($self->room, [])
    unless ($self->house->get_room($self->room));
	my $room = $self->house->get_room($self->room);
	push @{$room}, $self;

	# Create zone devices
    for (my $z=1; $z<=3; $z++){ 

    	# create the new zone
    	my $new_zone = DenonZone->new(parent => $self,
    		                          id   => $self->key . $z,
    	                              name => $self->name . ' Zone ' . $z);
    	my $zone_id  = $self->id . $z;
	    $self->house->set_device($zone_id, $new_zone);

	    # add the new zone to a room
	  	push @{$room}, $new_zone;
	}
};

sub set {
    my $self = shift;
    my $time = shift;
    my $delay = $time - AnyEvent->now;
    $self->_t( AnyEvent->timer( after=> $delay, cb=> $self->alarm));
}

sub html {
    my $html = <<END;
<span class="button" command='on'>Power On</span>
<span class="button" command='off'>Standby</span>
END
    return $html;
}

#----------------------------------------------------------------------------- 
# Denon Zone
package DenonZone;
use Moose;
use Template;
use namespace::autoclean;
extends 'Device';

has 'type' => ( is => 'ro', default => 'custom');
has 'parent' => ( is => 'rw' );
has 'css_style'   => ( is => 'ro', default => 'denon_zone');

sub json {
    my $self = shift;
    return {id => $self->key,
    	    name => $self->name,
    	    html => $self->html(),
    	    type => $self->type};
}

sub html {
    my $template = <<ENDTEMPLATE;
<span class="heading3">Power</span>
<span class="button" command='on'>On</span>
<span class="button" command='off'>Off</span> 
<br class="clearboth"/>

<span class="heading3">Volume</span>
[%FOREACH v IN volume_steps -%]
	<span class="button button_small" command='volume' payload='[% v %]'>[% v %]dB</span>
[%END-%]
<br class="clearboth"/>

<form class="select">
<span class="heading3">Source</span>
<select name="[% zone %].Source" class="source">
    [%FOREACH source IN sources -%]
    <option class="source" value='[% source %]'>[% source %]</option>
	[%END-%]
</select>
</form>
<br class="clearboth"/>
ENDTEMPLATE
    my $html = '';
	my @sources = ('TUNER','PHONO','CD','DVD','HDP','TV/CBL',
	               'SAT','VCR','DVR','V.AUX','NET/USB','XM');
	my @volume_steps = (-10, -3, -1, 1, 3, 10);
	my $tt = Template->new();
    $tt->process(\$template, { 'sources' => \@sources,
                               'volume_steps' => \ @volume_steps },
                 \$html );
    return $html;
}

1;