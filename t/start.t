use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Test::Trap qw/:die/;
use Encode qw(encode decode);
use JSON::PP;
use File::Spec;
use Beauth;
$ENV{"BEAUTH_MODE"} = 'test';

subtest 'File' => sub {
    my $script =
      File::Spec->catfile( $FindBin::RealBin, '..', 'script', 'beauth' );
    ok( -x $script, "script file: $script" );
    my $sql = File::Spec->catfile( $FindBin::RealBin, '..', 'beauth.sql' );
    ok( -e $sql, "sql file: $sql" );
};

subtest 'Class and Method' => sub {
    my @methods = qw{new};
    can_ok( new_ok('Beauth'), (@methods) );
};

subtest 'Build' => sub {
    my $build = new_ok('Beauth::Build');

    # my $error_msg = $build->start();
    # my @keys      = keys %{$error_msg};
    # my $key       = shift @keys;
    # ok( $key eq 'error', 'error message' );
    # for my $method ( 'init', 'insert', 'dump' ) {
    #     my $output = $build->start( { method => $method } );
    #     like( $output->{message}, qr/success/, $output->{message} );
    # }
    # {
    #     # db ファイル削除して新しくできたもので検索テスト
    #     my $db = $build->db_file_path;
    #     unlink $db;
    #     ok( !-e $db, 'db file' );
    #     my $output = $build->start( { method => 'restore' } );
    #     like( $output->{message}, qr/success/, $output->{message} );
    # }
};

subtest 'User' => sub {
    ok(1);

    # my $build = new_ok('Mhj::Build');
    # $build->run( { method => 'init' } );
    # my $user      = new_ok('Mhj::User');
    # my $error_msg = $user->run();
    # my @keys      = keys %{$error_msg};
    # my $key       = shift @keys;
    # ok( $key eq 'error', 'error message' );
    # my $insert_q = +{
    #     path   => "user",
    #     method => "insert",
    #     params => +{
    #         loginid  => 'info@becom.co.jp',
    #         password => "info"
    #     }
    # };
    # my $insert = $user->run($insert_q);
    # ok( $insert->{loginid} eq $insert_q->{params}->{loginid},   'insert' );
    # ok( $insert->{password} eq $insert_q->{params}->{password}, 'insert' );

    # my $get_q = +{
    #     path   => "user",
    #     method => "get",
    #     params => +{ loginid => $insert->{loginid}, }
    # };
    # my $get = $user->run($get_q);
    # ok( $get->{loginid} eq $insert->{loginid},   'get' );
    # ok( $get->{password} eq $insert->{password}, 'get' );

    # my $list_q = +{
    #     path   => "user",
    #     method => "list",
    #     params => +{}
    # };
    # my $list = $user->run($list_q);
    # ok( $list->[0]->{loginid} eq $get->{loginid},   'list' );
    # ok( $list->[0]->{password} eq $get->{password}, 'list' );

    # my $update_q = +{
    #     path   => "user",
    #     method => "update",
    #     params => +{
    #         id       => $insert->{id},
    #         loginid  => 'info2@becom.co.jp',
    #         password => "info2"
    #     }
    # };
    # my $update = $user->run($update_q);
    # ok( $update->{loginid} eq $update_q->{params}->{loginid},   'update' );
    # ok( $update->{password} eq $update_q->{params}->{password}, 'update' );

    # my $delete_q = +{
    #     path   => "user",
    #     method => "delete",
    #     params => +{ id => $insert->{id}, }
    # };
    # my $delete = $user->run($delete_q);
    # ok( !%{$delete}, 'delete' );
};

done_testing;

__END__
