package Beauth;
use strict;
use warnings;
use utf8;
use FindBin;
use JSON::PP;
use File::Spec;
use DBI;
use Time::Piece;
use Time::Seconds;
use Data::Dumper;
use Beauth::Build;
use Beauth::Error;
use Beauth::User;
use Beauth::Login;

# class
sub new   { bless {}, shift; }
sub build { Beauth::Build->new }
sub error { Beauth::Error->new }
sub user  { Beauth::User->new }
sub login { Beauth::Login->new }

# helper
sub time_stamp { localtime->datetime( 'T' => ' ' ); }

sub ts_10_days_later {
    my $t = localtime;
    $t += ( ONE_DAY * 10 );
    return $t->datetime( 'T' => ' ' );
}

sub is_test_mode {
    return if !$ENV{"BEAUTH_MODE"};
    return if $ENV{"BEAUTH_MODE"} ne 'test';
    return 1;
}

sub dump {
    my ( $self, @args ) = @_;
    my $d = Data::Dumper->new( [ shift @args ] );
    return $d->Dump;
}

# $self->single($table, \@cols, \%params);
sub single {
    my ( $self, $table, $cols, $params ) = @_;
    my $sql_q = [];
    for my $col ( @{$cols} ) {
        push @{$sql_q}, qq{$col = "$params->{$col}"};
    }
    push @{$sql_q}, qq{deleted = 0};
    my $sql_clause = join " AND ", @{$sql_q};
    my $sql        = qq{SELECT * FROM $table WHERE $sql_clause};
    my $dbh        = $self->build_dbh;
    return $dbh->selectrow_hashref($sql);
}

# $self->rows($table, \@cols, \%params);
sub rows {
    my ( $self, $table, $cols, $params ) = @_;
    my $sql_q = [];
    for my $col ( @{$cols} ) {
        push @{$sql_q}, qq{$col = "$params->{$col}"};
    }
    push @{$sql_q}, qq{deleted = 0};
    my $sql_clause = join " AND ", @{$sql_q};
    my $sql        = qq{SELECT * FROM $table WHERE $sql_clause};
    my $dbh        = $self->build_dbh;
    my $hash       = $dbh->selectall_hashref( $sql, 'id' );
    my $arrey_ref  = [];
    for my $key ( sort keys %{$hash} ) {
        push @{$arrey_ref}, $hash->{$key};
    }
    return $arrey_ref;
}

sub db_insert {
    my ( $self, @args ) = @_;
    my ( $table, $cols, $data ) = @args;
    my $col    = join ",", @{$cols};
    my $values = join ",", map { '?' } @{$cols};
    my $sql    = qq{INSERT INTO $table ($col) VALUES ($values)};
    my $dbh    = $self->build_dbh;
    my $sth    = $dbh->prepare($sql);
    $sth->execute( @{$data} ) or die $dbh->errstr;
    my $id     = $dbh->last_insert_id( undef, undef, undef, undef );
    my $create = $self->single( $table, ['id'], { id => $id } );
    return $create;
}

sub db_update {
    my ( $self, @args ) = @_;
    my $update_row = shift @args;
    my $set_args   = shift @args;
    my $where_args = shift @args;

    my $table        = $update_row->{table};
    my $update_id    = $update_row->{row}->{id};
    my $set_clause   = $self->set_clause( @{$set_args} );
    my $where_clause = $self->where_clause( @{$where_args} );

    my $sql = qq{UPDATE $table SET $set_clause WHERE $where_clause};
    my $dbh = $self->build_dbh;
    my $sth = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    my $update = $self->single( $table, ['id'], { id => $update_id } );
    return $update;
}

sub set_clause {
    my ( $self, @args ) = @_;
    my $cols   = shift @args;
    my $params = shift @args;
    my $dt     = $self->time_stamp;
    my $set_q  = [];
    for my $col ( @{$cols} ) {
        push @{$set_q}, qq{$col = "$params->{$col}"};
    }
    push @{$set_q}, qq{modified_ts = "$dt"};
    my $set_clause = join ",", @{$set_q};
    return $set_clause;
}

sub where_clause {
    my ( $self, @args ) = @_;
    my $cols    = shift @args;
    my $params  = shift @args;
    my $where_q = [];
    for my $col ( @{$cols} ) {
        push @{$where_q}, qq{$col = "$params->{$col}"};
    }
    push @{$where_q}, qq{deleted = "0"};
    my $where_clause = join " AND ", @{$where_q};
    return $where_clause;
}

# file
sub home           { File::Spec->catfile( $FindBin::RealBin, '..' ); }
sub homedb         { File::Spec->catfile( home(),            'db' ); }
sub homebackup     { File::Spec->catfile( home(),            'backup' ); }
sub db_file_path   { File::Spec->catfile( homedb(),          db_file() ); }
sub sql_file_path  { File::Spec->catfile( home(),            'beauth.sql' ); }
sub dump_file_path { File::Spec->catfile( homebackup(),      dump_file() ); }

sub dump_file {
    return 'beauth-test.dump' if is_test_mode();
    return 'beauth.dump';
}

sub db_file {
    return 'beauth-test.db' if is_test_mode();
    return 'beauth.db';
}

sub insert_csv {
    my ( $self, @args ) = @_;
    my $name = shift @args;
    return File::Spec->catfile( homebackup(), $name ) if is_test_mode();
    return File::Spec->catfile( homebackup(), $name );
}

sub build_dbh {
    my ( $self, @args ) = @_;
    my $db   = $self->db_file_path;
    my $attr = +{
        RaiseError     => 1,
        AutoCommit     => 1,
        sqlite_unicode => 1,
    };
    my $dbh = DBI->connect( "dbi:SQLite:dbname=$db", "", "", $attr );
    return $dbh;
}

1;

__END__
