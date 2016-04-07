package DBIx::Model::Column;
use strict;
use warnings;
use Moo;
use Types::Standard qw/ArrayRef Bool Int Str Undef/;

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

has primary => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
);

has size => (
    is  => 'ro',
    isa => Int | Undef,
);

has target_count => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

has type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has nullable => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

sub as_string {
    my $self   = shift;
    my $prefix = shift;
    my $str    = $prefix . $self->name . ' ' . $self->type;
    $str .= '(' . $self->size . ')' if $self->size;
    $str .= ' NOT NULL' unless $self->nullable;
    return $str;
}

sub bump_target_count {
    my $self = shift;
    $self->target_count( $self->target_count + 1 );
    $self->table->bump_target_count;
}

sub full_name {
    my $self = shift;
    return $self->table->name . '.' . $self->name;
}

1;
