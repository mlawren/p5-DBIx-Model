package DBIx::Model;
use strict;
use warnings;
use DBIx::Model::DB;

our @VERSION = '0.0.1';

sub DBI::db::model {
    my $dbh = shift;

    my $db = DBIx::Model::DB->new( name => $dbh->{Name}, @_ );
    my @fk;

    my $t_sth = $dbh->table_info;
    while ( my $t_ref = $t_sth->fetchrow_hashref ) {
        if ( $t_ref->{TABLE_TYPE} eq 'TABLE' ) {

            my $table = $db->add_table( name => $t_ref->{TABLE_NAME} );
            my @primary = $dbh->primary_key( '%', '%', $t_ref->{TABLE_NAME} );

            my $c_sth =
              $dbh->column_info( '%', '%', $t_ref->{TABLE_NAME}, '%' );
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
                        $t_ref->{TABLE_NAME}, $fk_ref->{PKTABLE_NAME},
                        [ $fk_ref->{FKCOLUMN_NAME}, $fk_ref->{PKCOLUMN_NAME} ]
                    );
                }
                else {
                    push( @x,
                        [ $fk_ref->{FKCOLUMN_NAME}, $fk_ref->{PKCOLUMN_NAME} ]
                    );
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

    return $db;
}

1;

=head1 NAME

DBIx::Model - build a Perl object model of a database

