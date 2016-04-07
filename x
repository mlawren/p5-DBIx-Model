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

my $dbh   = DBI->connect( $opts->{dsn} );
my $db    = db->new( name => $opts->{dsn} );
my $t_sth = $dbh->table_info;

sub exclude {
    my $name = shift;
    my $list = shift;
    foreach my $try (@$list) {
        return 1 if $name =~ m/$try/;
    }
    return 0;
}

my @fk;

while ( my $t_ref = $t_sth->fetchrow_hashref ) {
    if ( $t_ref->{TABLE_TYPE} eq 'TABLE' ) {
        next if exclude( $t_ref->{TABLE_NAME}, $opts->{exclude} );

        my $table = $db->add_table( name => $t_ref->{TABLE_NAME} );
        my @primary = $dbh->primary_key( '%', '%', $t_ref->{TABLE_NAME} );

        my $c_sth = $dbh->column_info( '%', '%', $t_ref->{TABLE_NAME}, '%' );
        while ( my $c_ref = $c_sth->fetchrow_hashref ) {
            my $pri = grep { $c_ref->{COLUMN_NAME} eq $_ } @primary;
            $table->add_column(
                name     => $c_ref->{COLUMN_NAME},
                nullable => $c_ref->{NULLABLE},
                size     => $c_ref->{COLUMN_SIZE},
                type     => $c_ref->{TYPE_NAME},
                primary  => $pri ? 1 : 0,
            );
        }

        my $fk_sth =
          $dbh->foreign_key_info( '%', '%', '%', '%', '%',
            $t_ref->{TABLE_NAME} );

        my @x;
        while ( my $fk_ref = $fk_sth->fetchrow_hashref ) {
            if ( $fk_ref->{KEY_SEQ} == 1 ) {
                if (@x) {
                    push( @fk, [@x] );
                }
                @x = (
                    $t_ref->{TABLE_NAME},
                    $fk_ref->{PKTABLE_NAME},
                    [ $fk_ref->{FKCOLUMN_NAME}, $fk_ref->{PKCOLUMN_NAME} ]
                );
            }
            else {
                push( @x,
                    [ $fk_ref->{FKCOLUMN_NAME}, $fk_ref->{PKCOLUMN_NAME} ] );
            }
        }

        if (@x) {
            push( @fk, [@x] );
        }
    }
}

foreach my $fk (@fk) {
    my ($from) = grep { $_->name eq $fk->[0] } $db->tables;
    my ($to)   = grep { $_->name eq $fk->[1] } $db->tables;
    shift @$fk;
    shift @$fk;

    my @from;
    my @to;

    foreach my $pair (@$fk) {
        push( @from, grep { $_->name eq $pair->[0] } $from->columns );
        push( @to,   grep { $_->name eq $pair->[1] } $to->columns );
    }

    $from->add_foreign_key(
        to_table   => $to,
        columns    => \@from,
        to_columns => \@to,
    );
}

print $db->as_string . "\n";
