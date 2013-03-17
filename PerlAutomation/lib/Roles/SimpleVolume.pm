package SimpleVolume;
use Moose::Role;
use namespace::autoclean;

requires 'up';
requires 'down';
requires 'toggle_mute'; # toggle

1;