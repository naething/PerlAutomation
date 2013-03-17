package PerlAutomation;
use Dancer ':syntax';
use Template;
use Data::Dumper;
use Dancer::Plugin::Ajax;

set 'template'   => 'template_toolkit';
set 'serializer' => 'JSON';

our $VERSION = '0.1';

#**************************************************************************#
# The index page
get '/' => sub {
     redirect '/Devices';
};

get '/Devices' => sub {
    my $house = request->{env}->{house};
    template 'index' => { 'rooms'   => $house->rooms,
                          'devices' => $house->devices };
};

ajax '/Devices' => sub {
    my $house = request->{env}->{house};
    my @dev;
    for my $k (keys(%{$house->devices})){
        my $d = $house->get_device($k);
        push @dev, $d->json();
    }
    return \@dev;
};


ajax '/command' => sub {
    my $house = request->{env}->{house};
    my $cmd = params('body')->{'command'};
    my $dev_id   = $cmd->{'id'};

    my $dev = $house->get_device($dev_id);
    $dev->command($cmd);

    print Dumper($cmd);
};

1;