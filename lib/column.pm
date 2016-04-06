package column;
use strict;
use warnings;
use column;
use Moo;
use Types::Standard qw/Str ArrayRef/;

our $VERSION = '0.0.1';

has table => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub as_string {
    my $self   = shift;
    my $prefix = shift;
    my $str    = $prefix . $self->name . ' ' . $self->type;
    return $str;
}

1;
