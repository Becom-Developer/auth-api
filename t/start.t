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
use Beauth::Render;
$ENV{"BEAUTH_MODE"} = 'test';

subtest 'File' => sub {
    my $script =
      File::Spec->catfile( $FindBin::RealBin, '..', 'script', 'beauth' );
    ok( -x $script, "script file: $script" );
    my $sql = File::Spec->catfile( $FindBin::RealBin, '..', 'beauth.sql' );
    ok( -e $sql, "sql file: $sql" );
};

subtest 'Class and Method' => sub {
    my @methods = (
        'new',           'time_stamp',     'is_test_mode', 'dump',
        'home',          'homedb',         'homebackup',   'db_file_path',
        'sql_file_path', 'dump_file_path', 'dump_file',    'db_file',
        'insert_csv',    'build_dbh'
    );
    can_ok( new_ok('Beauth'),         (@methods) );
    can_ok( new_ok('Beauth::Render'), (@methods) );
    can_ok( new_ok('Beauth::Error'),  (@methods) );
    can_ok( new_ok('Beauth::Build'),  (@methods) );
};

subtest 'Framework Render' => sub {
    my $obj   = new_ok('Beauth::Render');
    my $chars = '日本語';
    {
        my $bytes = encode( 'UTF-8', $chars );
        trap { $obj->raw($chars) };
        like( $trap->stdout, qr/$bytes/, 'render method raw' );
    }
    {
        my $hash  = { jang => $chars };
        my $bytes = encode_json($hash);
        trap { $obj->all_items_json($hash) };
        like( $trap->stdout, qr/$bytes/, 'render method all_items_json' );
    }
};

subtest 'Framework Error' => sub {
    my $obj   = new_ok('Beauth::Error');
    my $chars = '予期せぬエラー';
    {
        my $hash = $obj->commit($chars);
        like( $hash->{error}->{message}, qr/$chars/, "error commit" );
    }
    {
        my $hash  = $obj->commit($chars);
        my $bytes = encode_json($hash);
        trap { $obj->output($chars); };
        like( $trap->stdout, qr/$bytes/, 'error output' );
    }
};

subtest 'Framework Build' => sub {
    my $obj  = new_ok('Beauth::Build');
    my $hash = $obj->start();
    my @keys = keys %{$hash};
    my $key  = shift @keys;
    ok( $key eq 'error', 'error message' );
    {
        my $args = { method => 'init' };
        my $hash = $obj->start($args);
        like( $hash->{message}, qr/success/, 'success init' );
    }
    {
        my $args = {
            method => 'insert',
            params => {
                csv   => 'user-test.csv',
                table => 'user',
                cols  => [
                    'loginid',    'password', 'approved', 'deleted',
                    'created_ts', 'modified_ts',
                ]
            }
        };
        my $hash = $obj->start($args);
        like( $hash->{message}, qr/success/, 'success insert' );
    }
    {
        my $args = { method => 'dump', };
        my $hash = $obj->start($args);
        like( $hash->{message}, qr/success/, 'success dump' );
    }

    {
        my $db = $obj->db_file_path;
        unlink $db;
        ok( !-e $db, "delete db file" );
        my $args = { method => 'restore', };
        my $hash = $obj->start($args);
        like( $hash->{message}, qr/success/, 'success restore' );
    }
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
