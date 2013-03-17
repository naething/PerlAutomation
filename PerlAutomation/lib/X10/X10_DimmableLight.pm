package X10_DimmableLight;

use Moose;
use namespace::autoclean;

with 'DimmableLight';

has 'interface' => (
   is => 'ro',
   isa => 'X10_Interface',
);

has 'address' => (
   is => 'rw',
   isa => 'X10_Address',
);

sub 'on' {
  my $self = shift;
  interface->
}
