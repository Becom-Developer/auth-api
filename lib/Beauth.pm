package Beauth;
use strict;
use warnings;
use utf8;
use FindBin;
use JSON::PP;
use File::Spec;
use DBI;
use Time::Piece;
use Data::Dumper;
use Beauth::Build;
use Beauth::Error;
use Beauth::User;

# class
sub new   { bless {}, shift; }
sub build { Beauth::Build->new }
sub error { Beauth::Error->new }
sub user  { Beauth::User->new }

# helper
sub time_stamp { localtime->datetime( 'T' => ' ' ); }

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
