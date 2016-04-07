package DBIx::Model::FK;
use strict;
use warnings;
use Scalar::Util qw/weaken/;
use Moo;
use Types::Standard qw/ArrayRef/;

our $VERSION = '0.0.1';

has _columns => (
    is       => 'ro',
    isa      => ArrayRef,
    init_arg => 'columns',
    required => 1,
);

has table => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has _to_columns => (
    is       => 'ro',
    isa      => ArrayRef,
    init_arg => 'to_columns',
    required => 1,
);

has to_table => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub BUILD {
    my $self = shift;

    my @list = @{ $self->_columns };
    foreach my $i ( 0 .. $#list ) {
        weaken( $self->_columns->[$i] );
    }

    @list = @{ $self->_to_columns };
    foreach my $i ( 0 .. $#list ) {
        weaken( $self->_to_columns->[$i] );
    }
}

sub as_string {
    my $self   = shift;
    my $prefix = shift;
    my $str =
        $prefix
      . "FOREIGN KEY("
      . join( ',', map { $_->name } $self->columns )
      . ') REFERENCES '
      . $self->to_table->name . '('
      . join( ',', map { $_->name } $self->to_columns ) . ')';

    return $str;
}

sub columns {
    my $self = shift;
    return @{ $self->_columns } if wantarray;
    return $self->_columns;
}

sub to_columns {
    my $self = shift;
    return @{ $self->_to_columns } if wantarray;
    return $self->_to_columns;
}

1;
