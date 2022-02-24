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
    can_ok( new_ok('Beauth::User'),   (@methods) );
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
    {
        my $obj  = new_ok('Beauth::Build');
        my $args = { method => 'init' };
        my $hash = $obj->start($args);
        like( $hash->{message}, qr/success/, 'success init' );
    }
    my $obj  = new_ok('Beauth::User');
    my $hash = $obj->run();
    my @keys = keys %{$hash};
    my $key  = shift @keys;
    ok( $key eq 'error', 'error message' );
    my $sample = +{ loginid => 'info@becom.co.jp', password => "info" };
    {
        my $q    = +{ method => "insert", params => $sample, };
        my $hash = $obj->run($q);
        ok( $hash->{loginid} eq $q->{params}->{loginid},   'insert' );
        ok( $hash->{password} eq $q->{params}->{password}, 'insert' );
    }
    {
        my $q =
          +{ method => "get", params => +{ loginid => $sample->{loginid}, } };
        my $hash = $obj->run($q);
        ok( $hash->{loginid} eq $sample->{loginid},   'get' );
        ok( $hash->{password} eq $sample->{password}, 'get' );
    }
    {
        my $q    = +{ method => "list", params => +{} };
        my $rows = $obj->run($q);
        ok( $rows->[0]->{loginid} eq $sample->{loginid},   'list' );
        ok( $rows->[0]->{password} eq $sample->{password}, 'list' );
    }
    {
        my $q =
          { method => "get", params => { loginid => $sample->{loginid} } };
        my $id = $obj->run($q)->{id};
        $q->{method} = 'update';
        $q->{params} = +{
            id       => $id,
            loginid  => 'info2@becom.co.jp',
            password => 'info2',
        };
        my $hash = $obj->run($q);
        ok( $hash->{loginid} eq $q->{params}->{loginid},   'update' );
        ok( $hash->{password} eq $q->{params}->{password}, 'update' );
        $q->{params}->{loginid}  = $sample->{loginid};
        $q->{params}->{password} = $sample->{password};
        my $loginid = $obj->run($q)->{loginid};
        ok( $loginid eq $sample->{loginid}, 'update' );
    }
    {
        my $q =
          { method => "get", params => { loginid => $sample->{loginid} } };
        my $id = $obj->run($q)->{id};
        $q->{method} = 'delete';
        $q->{params} = +{ id => $id, };
        my $hash = $obj->run($q);
        ok( !%{$hash}, 'delete' );
        $q->{method} = 'get';
        $q->{params} = { loginid => $sample->{loginid} };
        my $error = $obj->run($q)->{error};
        ok( $error->{message}, 'delete' );
    }
};

done_testing;

__END__
