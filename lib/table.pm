package table;
use strict;
use warnings;
use Types::Standard qw/ArrayRef/;
use Moo;
use column;

our $VERSION = '0.0.1';

has _columns => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

has db => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has name => (
    is       => 'ro',
    required => 1,
);

sub add_column {
    my $self = shift;
    my $col = column->new( @_, table => $self );
    push( @{ $self->_columns }, $col );
    return $col;
}

sub columns {
    my $self = shift;
    return @{ $self->_columns } if wantarray;
    return $self->_columns;
}

sub as_string {
    my $self   = shift;
    my $prefix = shift;
    my $str    = $prefix . $self->name;

    foreach my $col ( $self->columns ) {
        $str .= "\n" . $col->as_string( $prefix . '  ' );
    }

    return $str;
}

1;
