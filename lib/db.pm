package db;
use strict;
use warnings;
use Type::Tiny;
use Types::Standard qw/ArrayRef Str/;
use Moo;
use table;

our $VERSION = '0.0.1';

my $Table = Type::Tiny->new(
    name       => 'Table',
    constraint => sub { ref($_) eq 'table' },
    message    => sub { "$_ ain't a table" },
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
    my $table = table->new( @_, db => $self );
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

my $db = db->new( name => 'bif' );

my $table = $db->add_table( name => 'bifkv' );
$table->add_column( name => 'bifkv',   type => 'int' );
$table->add_column( name => 'id',      type => 'int' );
$table->add_column( name => 'node_id', type => 'int' );
$table->add_column( name => 'name',    type => 'varchar' );

print $db->as_string . "\n";
