package DBIx::Model;
use strict;
use warnings;
use DBIx::Model::DB;

our $VERSION = '0.0.1_2';

my %columns;
my %forward;
my %backward;

sub DBI::db::model {
    my $dbh     = shift;
    my $catalog = shift;
    my $schema  = shift;
    my $names   = shift // '%';
    my $type    = shift // 'TABLE,VIEW';

    my $db = DBIx::Model::DB->new(
        name        => $dbh->{Name},
        catalog     => $catalog,
        schema      => $schema,
        table_types => $type,
    );
    my @raw_fk;

    my $t_sth =
      $dbh->table_info( $db->catalog, $db->schema, $names, $db->table_types );

    my $trefs = $t_sth->fetchall_hashref('TABLE_NAME');
    foreach my $tname ( sort keys %$trefs ) {
        my $table = $db->add_table(
            name => $tname,
            type => $trefs->{$tname}->{TABLE_TYPE}
        );

        my @primary = $dbh->primary_key( $db->catalog, $db->schema, $tname );
        my $c_sth = $dbh->column_info( $db->catalog, $db->schema, $tname, '%' );

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
            $db->catalog, $db->schema, $tname );

        my @x;
        while ( my $fk_ref = $fk_sth->fetchrow_hashref ) {
            next unless defined $fk_ref->{PKCOLUMN_NAME};    # mysql?

            if ( $fk_ref->{KEY_SEQ} == 1 ) {
                if (@x) {
                    push( @raw_fk, [@x] );
                }
                @x = (
                    lc $tname,
                    lc $fk_ref->{PKTABLE_NAME},
                    [
                        lc $fk_ref->{FKCOLUMN_NAME}, lc $fk_ref->{PKCOLUMN_NAME}
                    ]
                );
            }
            else {
                push(
                    @x,
                    [
                        lc $fk_ref->{FKCOLUMN_NAME}, lc $fk_ref->{PKCOLUMN_NAME}
                    ]
                );
            }
        }

        if (@x) {
            push( @raw_fk, [@x] );
        }
    }

    foreach my $fk (@raw_fk) {
        my ($from) =
          grep { $_->name_lc eq $fk->[0] } $db->tables;
        my ($to) = grep { $_->name_lc eq $fk->[1] } $db->tables;
        shift @$fk;
        shift @$fk;

        my @from;
        my @to;

        foreach my $pair (@$fk) {
            push( @from, grep { $_->name_lc eq $pair->[0] } $from->columns );
            push( @to,   grep { $_->name_lc eq $pair->[1] } $to->columns );
        }

        $from->add_foreign_key(
            to_table   => $to,
            columns    => \@from,
            to_columns => \@to,
        );

        map { $columns{ $_->full_name_lc } = $_ } @from, @to;
        map {
            $forward{ $to[$_]->full_name_lc }->{ $from[$_]->full_name_lc }++;
            $backward{ $from[$_]->full_name_lc }->{ $to[$_]->full_name_lc }++;
        } 0 .. ( ( scalar @from ) - 1 );
    }

    my $chain = 1;
    while ( my $key = ( sort keys %forward, keys %backward )[0] ) {
        chainer( $key, $chain++ );
    }

    $db->chains( $chain - 1 );
    %columns = %forward = %backward = ();
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

