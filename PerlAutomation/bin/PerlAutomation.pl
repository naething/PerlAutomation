#!/usr/bin/env perl

# Author: Rick Naething

# Just because these are a "good" idea
use Modern::Perl;

# For our static web page handling
use Dancer;
use PerlAutomation;

# Event Based Programming
use AnyEvent;
use AnyEvent::Debug;

# Our Automation Classes
use House;
use Denon::Denon;
use Vera::Vera;

# General Web framework classes / Websockets
use Plack::Builder;
use PocketIO;
use Plack::App::File;

use Data::Dumper;

setting apphandler => 'PSGI';

my $root;
my $websockets;

BEGIN {
    use File::Basename ();
    use File::Spec     ();

    $root = File::Basename::dirname(__FILE__) . '/..';
    $root = File::Spec->rel2abs($root);

    unshift @INC, "$root/../../lib";
}

#**************************************************************************#
sub send_broadcast {
    my $msg = shift;
    my $pool = $websockets->pool;
    foreach my $c ( keys%{$pool->{'connections'}} ) {
        my $sender = $pool->{'connections'}->{$c};
        $sender->sockets->emit( 'message', { text => $msg} );
    }
}

#**************************************************************************#
# When a device changes, it calls this
sub callback{
    my $device = shift;
    my $json_text = to_json($device->json());
    send_broadcast(($json_text));
};

#**************************************************************************#
#**************************************************************************#
# Configure our various devices
#**************************************************************************#
#**************************************************************************#

#use cm15a;

# Our global house ref
# Everything is accessible through this
my $house = House->new;

# Set up the Denon
# $house->set_device('denon', Denon->new(name => 'Denon 3808ci',
#                                       key   => 'denon',
#                                       ip   => '192.168.1.x',
#                                       port => '23',
#                                       room => 'A/V Equipment',
#                                       callback => \&callback,
#                                       house => $house));
# $house->get_device('denon')->connect();

# Set up Vera
$house->set_device('vera', Vera->new(name => 'MiCasaVerde Vera 3',
                                     key => 'vera',
                                     ip => '192.168.1.x',
                                     port => '3480',
                                     callback => \&callback,
                                     house => $house));
$house->get_device('vera')->connect();

# Set up the cm15a
#my $x10_interface = cm15a->new;
#$x10_interface->connect('192.168.1.141', '1099');

# Set up Debug Terminal
our $shell = AnyEvent::Debug::shell "unix/", "/Users/naething/shell";

#**************************************************************************#
#**************************************************************************#
# Set up our websocket and webpage handeling
#**************************************************************************#
#**************************************************************************#

$websockets = PocketIO->new(
        class => 'WebSocketHandler',
        method => 'run',
    );

# This sets up our Dancer static web page loading
my $app = sub {
    my $env = shift;
    $env->{house} = $house; # Here I add a ref to the house object,
                            # So it is accessible inside our route handling
    $env->{ws} = $websockets;
    my $request = Dancer::Request->new( env => $env );
    Dancer->dance($request);
};

builder {
    mount '/socket.io/socket.io.js' =>
      Plack::App::File->new(file => "$root/public/javascripts/socket.io.js");

    mount '/socket.io' => $websockets;

    mount "/" => builder {$app};
};





