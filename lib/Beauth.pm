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
use MIME::Base64;
use Beauth::Build;
use Beauth::Error;
use Beauth::User;
use Beauth::Login;
use Beauth::Webapi;
use SQLite::Simple;

# class
sub new    { bless {}, shift; }
sub build  { Beauth::Build->new }
sub error  { Beauth::Error->new }
sub user   { Beauth::User->new }
sub login  { Beauth::Login->new }
sub webapi { Beauth::Webapi->new }

# helper
sub time_stamp { localtime->datetime( 'T' => ' ' ); }

sub db {
    my ( $self, $args ) = @_;
    if ( !$args ) {
        $args = {};
    }
    my $simple = SQLite::Simple->new(
        {
            db_file_path   => $self->db_file_path,
            sql_file_path  => $self->sql_file_path,
            dump_file_path => $self->dump_file_path,
            %{$args},
        }
    );
    return $simple;
}

sub session_id {
    my ( $self, @args ) = @_;
    my $loginid   = shift @args;
    my $expiry_ts = $self->ts_10_days_later;

    # 4桁の簡易的な乱数
    my $rand = int rand(1000);
    my $id   = sprintf '%04d', $rand;
    my $sid  = encode_base64( "$loginid:$expiry_ts:$id", '' );
    return $sid;
}

sub apikey {
    my ( $self, @args ) = @_;
    my $loginid   = shift @args;
    my $target    = shift @args;
    my $expiry_ts = $self->ts_10_days_later;

    # 4桁の簡易的な乱数
    my $rand   = int rand(1000);
    my $id     = sprintf '%04d', $rand;
    my $apikey = encode_base64( "$loginid:$expiry_ts:$target:$id", '' );
    return $apikey;
}

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

sub is_root {
    my ( $self, @args ) = @_;
    my $params = shift @args;
    my $row =
      $self->valid_single( 'limitation', { loginid => $params->{loginid} } );
    return   if !$row;
    return 1 if $row->{status} eq '100';
    return;
}

sub is_general {
    my ( $self, @args ) = @_;
    my $params = shift @args;
    my $row =
      $self->valid_single( 'limitation', { loginid => $params->{loginid} } );
    return   if !$row;
    return 1 if $row->{status} eq '200';
    return;
}

sub sid_to_loginid {
    my ( $self, @args ) = @_;
    my $params = shift @args;
    my $row =
      $self->valid_single( 'login', { sid => $params->{sid}, loggedin => 1, } );
    return                 if !$row;
    return $row->{loginid} if $row;
}

sub is_valid_app {
    my ( $self, @args ) = @_;
    my $params = shift @args;

    # 暫定にここでappリスト書いておく
    my $list   = [ 'zsearch', 'mhj' ];
    my $target = $params->{target};
    return   if !$target;
    return 1 if grep { $_ eq $target } @{$list};
    return;
}

sub valid_single {
    my ( $self, $table, $params ) = @_;
    my $q_params = +{ %{$params}, deleted => 0, };
    return $self->db->single( $table, $q_params );
}

sub valid_search {
    my ( $self, $table, $params ) = @_;
    my $q_params = +{ %{$params}, deleted => 0, };
    return $self->db->search( $table, $q_params );
}

sub safe_insert {
    my ( $self, $table, $params ) = @_;
    my $dt = $self->time_stamp;
    my $insert_params =
      +{ %{$params}, deleted => 0, created_ts => $dt, modified_ts => $dt };
    return $self->db->insert( $table, $insert_params );
}

# $self->safe_update($table, \%search_params, \%update_params);
sub safe_update {
    my ( $self, $table, $search_params, $update_params ) = @_;
    my $dt       = $self->time_stamp;
    my $q_params = +{ %{$search_params}, deleted     => 0, };
    my $u_params = +{ %{$update_params}, modified_ts => $dt, };
    return $self->db->single_to( $table, $q_params )->update($u_params);
}

# file
sub home          { File::Spec->catfile( $FindBin::RealBin, '..' ); }
sub homedb        { File::Spec->catfile( home(),            'db' ); }
sub homebackup    { File::Spec->catfile( home(),            'backup' ); }
sub sql_file_path { File::Spec->catfile( home(),            'beauth.sql' ); }

sub dump_file_path {
    return $ENV{"BEAUTH_DUMP"} if $ENV{"BEAUTH_DUMP"};
    return File::Spec->catfile( homebackup(), 'beauth.dump' );
}

sub db_file_path {
    return $ENV{"BEAUTH_DB"} if $ENV{"BEAUTH_DB"};
    return File::Spec->catfile( homedb(), 'beauth.db' );
}

1;

__END__
