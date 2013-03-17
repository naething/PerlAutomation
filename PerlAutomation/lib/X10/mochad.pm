#***************************************************************************#
# X10 Interface (cm15a/cm19a via USB)
#***************************************************************************#
#
# Author: Rick Naething
# Version: 0.01
#

package cm15a;

use IO::Socket;
use Moose;
use namespace::autoclean;

use AnyEvent;
use AnyEvent::Handle;
use Data::Dumper;

#***************************************************************************#
# properties that deal with the connection
has '_ip'   => ( is => 'rw' );
has '_port' => ( is => 'rw' );
has '_fh'   => ( is => 'rw' );
has '_handle' => ( is => 'rw' );

has 'devices' => (
	is => 'ro',
	traits => [ 'Hash' ],
	isa => 'HashRef',
	default => sub { {} },
	handles => {
		get_ms => 'get',
		set_ms => 'set',
	},
);

#***************************************************************************#
# X10 Security Events
# Function/Key	 Description
# 0x0C	 Motion_alert_MS10A
# 0x8C	 Motion_normal_MS10A
# 0x04	 Contact_alert_min_DS10A
# 0x84	 Contact_normal_min_DS10A
# 0x00	 Contact_alert_max_DS10A
# 0x80	 Contact_normal_max_DS10A
# 0x01	 Contact_alert_min_low_DS10A
# 0x81	 Contact_normal_min_low_DS10A
# 0x05	 Contact_alert_max_low_DS10A
# 0x85	 Contact_normal_max_low_DS10A
# 0x06	 Arm_KR10A
# 0x86	 Disarm_KR10A
# 0x46	 Lights_On_KR10A
# 0xC6	 Lights_Off_KR10A
# 0x26	 Panic_KR10A

#***************************************************************************#
# Respond to events
#***************************************************************************#
sub receive_data{
	my $self = shift;
	
	# read line from socket
	my $line = $self->_handle->rbuf();
	$self->_handle->rbuf="";
	
	# unpack line
	# Format:
	# MM/DD, hh:mm:ss, Rx|Tx, PL/RF/RFSEC, House/HouseUnit/Addr, 
	#	<House Code>|<HouseCode><Unit Code>|<SecAddr>, Func:, <X10Func>
	my ($time, $date, $rx_tx, $physical_layer, $unused, $address, $unused, $x10func) = split(/ /,$line);

	warn $rx_tx; # rx | tx
	warn $physical_layer;

}

#***************************************************************************#
# Connection Functions
#***************************************************************************#
sub connect {
	my $self = shift;
	my $ip = shift;
	my $port = shift;
	
	# Connect to mochad.
	$self->_fh ( IO::Socket::INET->new (Proto => "tcp", PeerAddr => $ip, PeerPort => $port ) )
		or warn "can't connect\n";
	
	# now construct AnyEvent::Handler to watch the port for incoming data. We will still use
	# the fh to SEND data.
	$self->_handle ( AnyEvent::Handle->new (
		fh => ($self->_fh),
		on_connect => sub { warn('connected'); },
		on_eof => sub {warn "disconnected"; },
		on_read => sub {\$self->receive_data} ) );
};

sub set {
    my $self = shift;
    my $time = shift;
    my $delay = $time - AnyEvent->now;
    $self->_t( AnyEvent->timer( after=> $delay, cb=> $self->alarm));
}

1;