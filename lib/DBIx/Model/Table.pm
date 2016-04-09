package DBIx::Model::Table;
use strict;
use warnings;
use DBIx::Model::Column;
use DBIx::Model::FK;
use Types::Standard qw/ArrayRef Int/;
use Moo;

our $VERSION = '0.0.1_2';

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

has ref_count => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

has target_count => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

has _foreign_keys => (
    is       => 'ro',
    isa      => ArrayRef,
    default  => sub { [] },
    required => 1,
);

sub add_column {
    my $self = shift;
    my $col = DBIx::Model::Column->new( @_, table => $self );
    push( @{ $self->_columns }, $col );
    return $col;
}

sub add_foreign_key {
    my $self = shift;
    my $fk = DBIx::Model::FK->new( @_, table => $self );
    push( @{ $self->_foreign_keys }, $fk );
    return $fk;
}

sub as_string {
    my $self   = shift;
    my $prefix = shift;
    my $str    = $prefix . $self->name;

    foreach my $col ( $self->columns ) {
        $str .= "\n" . $col->as_string( $prefix . '  ' );
    }

    if ( my @pri = $self->primaries ) {
        $str .=
          "\n${prefix}  PRIMARY(" . join( ',', map { $_->name } @pri ) . ')';
    }

    foreach my $fk ( $self->foreign_keys ) {
        $str .= "\n" . $fk->as_string( $prefix . '  ' );
    }

    return $str;
}

sub bump_ref_count {
    my $self = shift;
    $self->ref_count( $self->ref_count + 1 );
}

sub bump_target_count {
    my $self = shift;
    $self->target_count( $self->target_count + 1 );
}

sub columns {
    my $self = shift;
    return @{ $self->_columns } if wantarray;
    return $self->_columns;
}

sub primaries {
    my $self = shift;
    return grep { $_->primary } $self->columns;
}

sub foreign_keys {
    my $self = shift;
    return @{ $self->_foreign_keys } if wantarray;
    return $self->_foreign_keys;
}

1;
