package DBIx::Model;
use strict;
use warnings;
use DBIx::Model::DB;

our $VERSION = '0.0.1_2';

my %columns;
my %forward;
my %backward;

sub DBI::db::model {
    my $dbh = shift;

    my $db = DBIx::Model::DB->new(
        catalog     => undef,
        name        => $dbh->{Name},
        schema      => undef,
        table_types => 'TABLE,VIEW',
        @_,
    );
    my @raw_fk;

    my $t_sth =
      $dbh->table_info( $db->catalog, $db->schema, '%', $db->table_types );

    while ( my $t_ref = $t_sth->fetchrow_hashref ) {
        my $table = $db->add_table( name => $t_ref->{TABLE_NAME} );
        my @primary =
          $dbh->primary_key( $db->catalog, $db->schema, $t_ref->{TABLE_NAME} );

        my $c_sth =
          $dbh->column_info( $db->catalog, $db->schema,
            $t_ref->{TABLE_NAME}, '%' );

        while ( my $c_ref = $c_sth->fetchrow_hashref ) {
            my $pri = grep { $c_ref->{COLUMN_NAME} eq $_ } @primary;
            $table->add_column(
                name     => $c_ref->{COLUMN_NAME},
                nullable => $c_ref->{NULLABLE},
                size     => $c_ref->{COLUMN_SIZE},
                type     => $c_ref->{TYPE_NAME} || '*UNKNOWN*',
                primary  => $pri ? 1 : 0,
            );
        }

        my $fk_sth =
          $dbh->foreign_key_info( $db->catalog, $db->schema, undef,
            $db->catalog, $db->schema, $t_ref->{TABLE_NAME} );

        my @x;
        while ( my $fk_ref = $fk_sth->fetchrow_hashref ) {
            next unless defined $fk_ref->{PKCOLUMN_NAME};    # mysql?

            if ( $fk_ref->{KEY_SEQ} == 1 ) {
                if (@x) {
                    push( @raw_fk, [@x] );
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
            push( @raw_fk, [@x] );
        }
    }

    foreach my $fk (@raw_fk) {
        my ($from) =
          grep { lc $_->name eq lc $fk->[0] } $db->tables;
        my ($to) = grep { lc $_->name eq lc $fk->[1] } $db->tables;
        shift @$fk;
        shift @$fk;

        my @from;
        my @to;

        foreach my $pair (@$fk) {
            push( @from, grep { lc $_->name eq lc $pair->[0] } $from->columns );
            push( @to,   grep { lc $_->name eq lc $pair->[1] } $to->columns );
        }

        $from->add_foreign_key(
            to_table   => $to,
            columns    => \@from,
            to_columns => \@to,
        );

        map { $columns{ lc $_->full_name } = $_ } @from, @to;
        map {
            $forward{ lc $to[$_]->full_name }->{ lc $from[$_]->full_name }++;
            $backward{ lc $from[$_]->full_name }->{ lc $to[$_]->full_name }++;
        } 0 .. ( ( scalar @from ) - 1 );
    }

    my $chain = 1;
    while ( my $key = ( sort keys %forward, keys %backward )[0] ) {
        chainer( $key, $chain++ );
    }

    $db->chains( $chain - 1 );
    return $db;
}

sub chainer {
    my $key   = shift;
    my $chain = shift;

    $columns{$key}->chain($chain);

    if ( my $val = delete $forward{$key} ) {
        foreach my $new ( sort keys %$val ) {
            chainer( $new, $chain );
        }
    }

    if ( my $val = delete $backward{$key} ) {
        foreach my $new ( sort keys %$val ) {
            chainer( $new, $chain );
        }
    }
}

1;

=head1 NAME

DBIx::Model - build a Perl object model of a database

