#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use DBI;
use OptArgs;
use db;

arg dsn => (
    isa      => 'Str',
    comment  => 'DBI connection string',
    required => 1,
);

opt name => (
    isa     => 'Str',
    comment => 'name of the database',
);

opt exclude => (
    alias   => 'e',
    isa     => 'ArrayRef',
    comment => 'table name(s) to exclude',
    default => sub { [] },
);

my $opts = optargs;
my $dbh  = DBI->connect( $opts->{dsn} );
my $db   = db->new( name => $opts->{dsn} );
my $sth  = $dbh->table_info;

sub exclude {
    my $name = shift;
    my $list = shift;
    foreach my $try (@$list) {
        return 1 if $name =~ m/$try/;
    }
    return 0;
}

while ( my $t_ref = $sth->fetchrow_hashref ) {
    if ( $t_ref->{TABLE_TYPE} eq 'TABLE' ) {
        unless ( exclude( $t_ref->{TABLE_NAME}, $opts->{exclude} ) ) {
            my $table = $db->add_table( name => $t_ref->{TABLE_NAME} );
            my $sth2 = $dbh->column_info( '%', '%', $t_ref->{TABLE_NAME}, '%' );

            while ( my $c_ref = $sth2->fetchrow_hashref ) {
                $table->add_column(
                    name     => $c_ref->{COLUMN_NAME},
                    nullable => $c_ref->{NULLABLE},
                    size     => $c_ref->{COLUMN_SIZE},
                    type     => $c_ref->{TYPE_NAME},
                );
            }
        }
    }
}

print $db->as_string;
