package DBIx::Model::DB;
use strict;
use warnings;
use Type::Tiny;
use Types::Standard qw/ArrayRef Int Str/;
use Moo;
use DBIx::Model::Table;

our $VERSION = '0.0.1';

my $Table = Type::Tiny->new(
    name       => 'Table',
    constraint => sub { ref($_) eq 'table' },
    message    => sub { "$_ ain't a table" },
);

has chains => (
    is  => 'rw',
    isa => Int,
);

has _tables => (
    is      => 'ro',
    isa     => ArrayRef [$Table],
    default => sub { [] },
);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub add_table {
    my $self = shift;
    my $table = DBIx::Model::Table->new( @_, db => $self );
    push( @{ $self->_tables }, $table );
    return $table;
}

sub tables {
    my $self = shift;
    return @{ $self->_tables } if wantarray;
    return $self->_tables;
}

sub as_string {
    my $self = shift;
    my $str  = $self->name;

    foreach my $table ( $self->tables ) {
        $str .= "\n" . $table->as_string('  ');
    }

    return $str;
}

1;
