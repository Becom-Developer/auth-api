use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Test::Trap qw/:die :output(systemsafe)/;
use Encode qw(encode decode);
use JSON::PP;
use File::Spec;
use MIME::Base64;
use Beauth;
use Beauth::Render;
use Beauth::CLI;
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
    can_ok( new_ok('Beauth::CLI'),    (@methods) );
    can_ok( new_ok('Beauth::Login'),  (@methods) );
};

subtest 'Framework Render' => sub {
    my $obj   = new_ok('Beauth::Render');
    my $chars = '日本語';
    subtest 'raw' => sub {
        my $bytes = encode( 'UTF-8', $chars );
        trap { $obj->raw($chars) };
        like( $trap->stdout, qr/$bytes/, 'render method raw' );
    };
    subtest 'all_items_json' => sub {
        my $hash  = { jang => $chars };
        my $bytes = encode_json($hash);
        trap { $obj->all_items_json($hash) };
        like( $trap->stdout, qr/$bytes/, 'render method all_items_json' );
    };
};

subtest 'Framework Error' => sub {
    my $obj   = new_ok('Beauth::Error');
    my $chars = '予期せぬエラー';
    subtest 'commit' => sub {
        my $hash = $obj->commit($chars);
        like( $hash->{error}->{message}, qr/$chars/, "error commit" );
    };
    subtest 'output' => sub {
        my $hash  = $obj->commit($chars);
        my $bytes = encode_json($hash);
        trap { $obj->output($chars); };
        like( $trap->stdout, qr/$bytes/, 'error output' );
    };
};

subtest 'Framework Build' => sub {
    my $obj = new_ok('Beauth::Build');
    my $msg = $obj->start()->{error}->{message};
    ok( $msg, 'error message' );
    subtest 'init' => sub {
        my $hash = $obj->start( { method => 'init' } );
        like( $hash->{message}, qr/success/, 'success init' );
    };
    subtest 'insert' => sub {
        my $hash = $obj->start(
            {
                method => 'insert',
                params => {
                    csv   => 'user-test.csv',
                    table => 'user',
                    cols  => [
                        'loginid',    'password',
                        'approved',   'deleted',
                        'created_ts', 'modified_ts',
                    ]
                }
            }
        );
        like( $hash->{message}, qr/success/, 'success insert' );
    };
    subtest 'dump' => sub {
        my $hash = $obj->start( { method => 'dump', } );
        like( $hash->{message}, qr/success/, 'success dump' );
    };
    subtest 'restore' => sub {
        my $db = $obj->db_file_path;
        unlink $db;
        ok( !-e $db, "delete db file" );
        my $hash = $obj->start( { method => 'restore', } );
        like( $hash->{message}, qr/success/, 'success restore' );
    };
};

subtest 'CLI' => sub {
    my $obj = new_ok('Beauth::CLI');
    trap { $obj->run() };
    like( $trap->stdout, qr/error/, 'error message' );
    trap { $obj->run('foo') };
    like( $trap->stdout, qr/error/, 'error message' );
    trap { $obj->run( 'foo', 'bar' ) };
    like( $trap->stdout, qr/error/, 'error message' );
    trap { $obj->run( 'build', 'init' ) };
    like( $trap->stdout, qr/success/, 'success init' );
};

subtest 'Script' => sub {
    my $script =
      File::Spec->catfile( $FindBin::RealBin, '..', 'script', 'beauth' );
    trap { system $script };
    like( $trap->stdout, qr/error/, 'error message' );
    trap { system "$script build init" };
    like( $trap->stdout, qr/success/, 'success init' );
};

subtest 'User' => sub {
    new_ok('Beauth::Build')->start( { method => 'init' } );
    my $obj = new_ok('Beauth::User');
    my $msg = $obj->run()->{error}->{message};
    ok( $msg, 'error message' );
    my $sample = +{ loginid => 'info@becom.co.jp', password => "info" };
    subtest 'insert' => sub {
        my $q    = +{ method => "insert", params => $sample, };
        my $hash = $obj->run($q);
        ok( $hash->{loginid} eq $q->{params}->{loginid},   'insert' );
        ok( $hash->{password} eq $q->{params}->{password}, 'insert' );
    };
    subtest 'get' => sub {
        my $q =
          +{ method => "get", params => +{ loginid => $sample->{loginid}, } };
        my $hash = $obj->run($q);
        ok( $hash->{loginid} eq $sample->{loginid},   'get' );
        ok( $hash->{password} eq $sample->{password}, 'get' );
    };
    subtest 'list' => sub {
        my $q    = +{ method => "list", params => +{} };
        my $rows = $obj->run($q);
        ok( $rows->[0]->{loginid} eq $sample->{loginid},   'list' );
        ok( $rows->[0]->{password} eq $sample->{password}, 'list' );
    };
    subtest 'update' => sub {
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
    };
    subtest 'delete' => sub {
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
    };
    subtest 'script insert' => sub {
        my $script =
          File::Spec->catfile( $FindBin::RealBin, '..', 'script', 'beauth' );
        my $bytes = encode_json($sample);
        trap { system "$script user insert --params='$bytes'" };
        my $chars = decode_json( $trap->stdout );
        like( $chars->{loginid}, qr/$sample->{loginid}/, 'success insert' );
    };
};

subtest 'Login' => sub {
    new_ok('Beauth::Build')->start( { method => 'init' } );
    my $obj = new_ok('Beauth::Login');
    my $msg = $obj->run()->{error}->{message};
    ok( $msg, 'error message' );
    my $sample = +{ loginid => 'info@becom.co.jp', password => "info" };
    new_ok('Beauth::User')->run( { method => "insert", params => $sample, } );
    subtest 'start to end' => sub {
        my $hash = $obj->run( { method => "start", params => $sample, } );
        my $sid  = decode_base64( $hash->{sid} );
        like( $sid, qr/$sample->{loginid}/, 'success sid' );
        my $status =
          $obj->run( { method => "status", params => { sid => $hash->{sid} } } )
          ->{status};
        like( $status, qr/200/, 'success login status' );
        $obj->run( { method => "end", params => { sid => $hash->{sid} } } );
        my $logout_status =
          $obj->run( { method => "status", params => { sid => $hash->{sid} } } )
          ->{status};
        like( $logout_status, qr/400/, 'success logout' );
    };
    subtest 'Duplicate login' => sub {
        my $args    = { method => "start", params => $sample, };
        my $sid     = $obj->run($args)->{sid};
        my $message = $obj->run($args)->{error}->{message};
        ok( $message, "error login" );
        $obj->run( { method => "end", params => { sid => $sid } } );
    };
    subtest 'Have a login history' => sub {
        my $args = { method => "start", params => $sample, };
        my $sid1 = $obj->run($args)->{sid};
        ok( $sid1, "ok login" );
        $obj->run( { method => "end", params => { sid => $sid1 } } );
        my $sid2 = $obj->run($args)->{sid};
        ok( $sid2, "ok login" );
        $obj->run( { method => "end", params => { sid => $sid2 } } );
        isnt( $sid1, $sid2, "Not duplicate" );
    };
    subtest 'refresh' => sub {
        my $start_args = { method => "start", params => $sample, };
        my $sid1       = $obj->run($start_args)->{sid};
        ok( $sid1, "ok login" );
        my $refrsh_args = { method => "refresh", params => { sid => $sid1 } };
        my $sid2        = $obj->run($refrsh_args)->{sid};
        ok( $sid2, "ok refresh" );
        isnt( $sid1, $sid2, "Not duplicate" );
        $obj->run( { method => "end", params => { sid => $sid2 } } );
    };
    subtest 'script login' => sub {
        my $script =
          File::Spec->catfile( $FindBin::RealBin, '..', 'script', 'beauth' );
        my $bytes = encode_json($sample);
        trap { system "$script login start --params='$bytes'" };
        my $chars = decode_json( $trap->stdout );
        ok( $chars->{sid}, "ok login" );
        my $bytes_sid = encode_json($chars);
        trap { system "$script login end --params='$bytes_sid'" };
        trap { system "$script login status --params='$bytes_sid'" };
        my $chars_status = decode_json( $trap->stdout );
        like( $chars_status->{status}, qr/400/, 'success logout' );
    };
};

done_testing;

__END__
