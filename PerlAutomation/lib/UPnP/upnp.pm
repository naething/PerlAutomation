package upnp;
use Moose;
use namespace::autoclean;
use Net::UPnP::ControlPoint;

has '_devices' => (is => 'rw');
has '_cp' => (is => 'rw');

sub init{
	my $self = shift;
	$self->_cp (Net::UPnP::ControlPoint->new);
}

sub refresh{
	my $self = shift;
	$self->_devices ($self->_cp->search(st =>'upnp:rootdevice', mx => 3) );
}

sub list_devices{
	my $self = shift;
	$self->_devices;
}

1;