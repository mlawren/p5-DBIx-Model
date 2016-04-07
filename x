#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use DBI;
use DBIx::Model;
use OptArgs;

arg dsn => (
    isa      => 'Str',
    comment  => 'DBI connection string',
    required => 1,
);

opt exclude => (
    alias   => 'e',
    isa     => 'ArrayRef',
    comment => 'table name(s) to exclude',
    default => sub { [] },
);

opt help => (
    alias   => 'h',
    isa     => 'Bool',
    comment => 'print full help message and exit',
    ishelp  => 1,
);

opt name => (
    isa     => 'Str',
    comment => 'name of the database',
);

my $opts = optargs;
$opts->{dsn} = 'dbi:SQLite:dbname=' . $opts->{dsn} if -f $opts->{dsn};

my $dbh = DBI->connect( $opts->{dsn} );
my $db  = $dbh->model(
    name    => $opts->{dsn},
    exclude => $opts->{exclude},
);

sub exclude {
    my $name = shift;
    my $list = shift;
    foreach my $try (@$list) {
        return 1 if $name =~ m/$try/;
    }
    return 0;
}

print $db->as_string . "\n";
