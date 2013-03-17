package WebSocketHandler;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

#has 'house', is => 'ro', 'isa' => 'HashRef', required => 1;
#has 'house', is => 'ro', required => 1;

sub run {

	my $self = shift;

    return sub {
        my $socket = shift;

        $socket->on('message' => sub {
                my $sender = shift;
                my ( $message ) = @_;

                #$sender->broadcast->emit( 'message', $message );
                $sender->sockets->emit( 'message', { text => $message } );
            });
    }
}

1;