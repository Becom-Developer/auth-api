use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Test::Trap qw/:die :output(systemsafe)/;
use Encode     qw(encode decode);
use JSON::PP;
use File::Spec;
use MIME::Base64;
use Beauth;
use Beauth::Render;
use Beauth::CLI;
use File::Temp qw/ tempfile tempdir /;
my $temp     = File::Temp->newdir( DIR => $FindBin::RealBin, CLEANUP => 1, );
my $test_dir = $temp->dirname;
$ENV{"BEAUTH_MODE"}    = 'test';
$ENV{"BEAUTH_TESTDIR"} = $test_dir;
$ENV{"BEAUTH_DUMP"}    = File::Spec->catfile( $test_dir, 'beauth.dump' );
$ENV{"BEAUTH_DB"}      = File::Spec->catfile( $test_dir, 'beauth.db' );

# 環境変数
# BEAUTH_MODE 実行モード
# BEAUTH_HOME プロジェクトのパス
# BEAUTH_TESTDIR テスト後に破棄するディレクトリ
# BEAUTH_DB データベースファイルのパス
# BEAUTH_SQL SQLファイルのパス
# BEAUTH_DUMP SQL dumpファイルのパス

subtest 'File' => sub {
    my $script =
      File::Spec->catfile( $FindBin::RealBin, '..', 'script', 'beauth' );
    ok( -x $script, "script file: $script" );
    my $sql = File::Spec->catfile( $FindBin::RealBin, '..', 'beauth.sql' );
    ok( -e $sql, "sql file: $sql" );
};

subtest 'Class and Method' => sub {
    my @methods = (
        'new',           'time_stamp', 'is_test_mode', 'dump',
        'home',          'homedb',     'homebackup',   'db_file_path',
        'sql_file_path', 'dump_file_path',
    );
    can_ok( new_ok('Beauth'),         (@methods) );
    can_ok( new_ok('Beauth::Render'), (@methods) );
    can_ok( new_ok('Beauth::Error'),  (@methods) );
    can_ok( new_ok('Beauth::Build'),  (@methods) );
    can_ok( new_ok('Beauth::User'),   (@methods) );
    can_ok( new_ok('Beauth::CLI'),    (@methods) );
    can_ok( new_ok('Beauth::Login'),  (@methods) );
    can_ok( new_ok('Beauth::Webapi'), (@methods) );
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
        my $commit_chars = decode( 'utf-8', $bytes );
        my $stdout_chars = decode( 'utf-8', $trap->stdout );
        chomp($stdout_chars);
        is( $commit_chars, $stdout_chars, 'error output' );
    };
};

subtest 'Framework Build' => sub {
    my $obj = new_ok('Beauth::Build');
    my $msg = $obj->start()->{error}->{message};
    ok( $msg, 'error message' );
    subtest 'init' => sub {
        my $hash = $obj->start( { method => 'init' } );
        like( $hash->{message}, qr/success/, 'success init' );
        my $file_name = 'beauth-stg.db';
        my $stg =
          $obj->start( { method => 'init', params => { name => $file_name } } );
        like( $stg->{message}, qr/$file_name/, 'success init' );
    };
    subtest 'insert' => sub {
        my $csv  = File::Spec->catfile( $FindBin::RealBin, 'user-test.csv' );
        my $hash = $obj->start(
            {
                method => 'insert',
                params => {
                    csv   => $csv,
                    table => 'user',
                    cols  => [
                        'loginid',    'password',
                        'approved',   'deleted',
                        'created_ts', 'modified_ts',
                    ],
                    time_stamp => [ 'created_ts', 'modified_ts', ],
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

# ログインユーザーを作成する以外は全て認証sid必要
subtest 'Login signup' => sub {
    new_ok('Beauth::Build')->start( { method => 'init' } );
    my $obj    = new_ok('Beauth::Login');
    my $sample = +{
        loginid    => 'info@becom.co.jp',
        password   => "info",
        limitation => "100"
    };
    my $hash = $obj->run( { method => "signup", params => $sample, } );
    my $sid  = decode_base64( $hash->{sid} );
    like( $sid, qr/$sample->{loginid}/, 'success sid' );
    my $user = $hash->{user};
    is( $user->{loginid},    $sample->{loginid},    'success loginid' );
    is( $user->{limitation}, $sample->{limitation}, 'success limitation' );
    my $res =
      $obj->run( { method => "status", params => { sid => $hash->{sid} } } );
    my $status = $res->{status};
    like( $status, qr/200/, 'success login status' );
    my $res_user = $res->{user};
    is( $res_user->{loginid},    $sample->{loginid},    'success loginid' );
    is( $res_user->{limitation}, $sample->{limitation}, 'success limitation' );
    subtest 'not id' => sub {
        my $sample =
          +{ loginid => '', password => "info", limitation => "100" };
        my $hash = $obj->run( { method => "signup", params => $sample, } );
        my $msg  = $hash->{error}->{message};
        ok( $msg, 'error message' );
    };
    subtest 'not password' => sub {
        my $sample = +{ loginid => '123', password => "", limitation => "100" };
        my $hash   = $obj->run( { method => "signup", params => $sample, } );
        my $msg    = $hash->{error}->{message};
        ok( $msg, 'error message' );
    };
};

# 権限 limitation についての挙動
subtest 'limitation' => sub {
    new_ok('Beauth::Build')->start( { method => 'init' } );
    my $obj = new_ok('Beauth::Login');
    subtest 'standard' => sub {
        my $standard = +{
            loginid  => 'limit_standard@becom.co.jp',
            password => "info",
        };
        my $hash = $obj->run( { method => "signup", params => $standard, } );
        my $user = $hash->{user};
        is( $user->{limitation}, 200, 'success limitation' );
    };
    subtest 'error101' => sub {
        my $error101 = +{
            loginid    => 'limit_error101@becom.co.jp',
            password   => "info",
            limitation => "101",
        };
        my $hash = $obj->run( { method => "signup", params => $error101, } );
        my $msg  = $hash->{error}->{message};
        ok( $msg, 'error message' );
    };
    subtest 'error201' => sub {
        my $error201 = +{
            loginid    => 'limit_error201@becom.co.jp',
            password   => "info",
            limitation => "201",
        };
        my $hash = $obj->run( { method => "signup", params => $error201, } );
        my $msg  = $hash->{error}->{message};
        ok( $msg, 'error message' );
    };
};

subtest 'User' => sub {
    new_ok('Beauth::Build')->start( { method => 'init' } );
    my $obj = new_ok('Beauth::User');
    my $msg = $obj->run()->{error}->{message};
    ok( $msg, 'error message' );
    my $sid = new_ok('Beauth::Login')->run(
        {
            method => "signup",
            params => +{
                loginid    => 'root@becom.co.jp',
                password   => "root",
                limitation => "100",
            },
        }
    )->{sid};
    my $sample =
      +{ loginid => 'info@becom.co.jp', password => "info", sid => $sid };
    my $signup_params = {
        method => "signup",
        params => +{
            loginid    => 'general@becom.co.jp',
            password   => "general",
            limitation => "200",
        },
    };
    my $general_sid = new_ok('Beauth::Login')->run($signup_params)->{sid};
    my $general_id  = $obj->run(
        {
            method => "get",
            params =>
              { loginid => $signup_params->{params}->{loginid}, sid => $sid }
        }
    )->{id};
    subtest 'insert' => sub {
        my $q    = +{ method => "insert", params => $sample, };
        my $hash = $obj->run($q);
        ok( $hash->{loginid} eq $q->{params}->{loginid},   'insert' );
        ok( $hash->{password} eq $q->{params}->{password}, 'insert' );
        ok( $obj->is_general( { loginid => $hash->{loginid} } ) );
        my $insert_params = +{
            loginid  => 'general2@becom.co.jp',
            password => "general2",
            sid      => $general_sid
        };
        my $insert_args = +{ method => "insert", params => $insert_params, };
        my $insert_msg  = $obj->run($insert_args)->{error}->{message};
        ok( $insert_msg, "error get" );
    };
    subtest 'get' => sub {
        my $params = { loginid => $sample->{loginid}, sid => $sample->{sid} };
        my $args   = +{ method => "get", params => $params };
        my $hash   = $obj->run($args);
        ok( $hash->{loginid} eq $sample->{loginid},   'get' );
        ok( $hash->{password} eq $sample->{password}, 'get' );
        my $get_params = {
            loginid => $signup_params->{params}->{loginid},
            sid     => $general_sid
        };
        my $get_args = +{ method => "get", params => $get_params };
        my $get_msg  = $obj->run($get_args)->{error}->{message};
        ok( $get_msg, "error get" );
    };
    subtest 'list' => sub {
        my $args = +{ method => "list", params => { sid => $sid } };
        my $rows = $obj->run($args);
        my $data = [ grep { $_->{loginid} eq $sample->{loginid} } @{$rows} ];
        ok( $data->[0]->{loginid} eq $sample->{loginid},   'list' );
        ok( $data->[0]->{password} eq $sample->{password}, 'list' );
        my $list_args =
          +{ method => "list", params => { sid => $general_sid } };
        my $list_msg = $obj->run($list_args)->{error}->{message};
        ok( $list_msg, "error list" );
    };
    subtest 'update' => sub {
        my $get_params  = { loginid => $sample->{loginid}, sid => $sid };
        my $get_args    = { method  => "get", params => $get_params };
        my $id          = $obj->run($get_args)->{id};
        my $update_args = {
            method => "update",
            params => {
                sid      => $sid,
                id       => $id,
                loginid  => 'info2@becom.co.jp',
                password => 'info2',
            }
        };
        my $hash = $obj->run($update_args);
        ok( $hash->{loginid} ne $update_args->{params}->{loginid},   'update' );
        ok( $hash->{password} eq $update_args->{params}->{password}, 'update' );
        my $re_update_args = {
            method => "update",
            params => {
                sid      => $sid,
                id       => $id,
                loginid  => $sample->{loginid},
                password => $sample->{password},
            }
        };
        my $loginid = $obj->run($re_update_args)->{loginid};
        ok( $loginid eq $sample->{loginid}, 'update' );
        my $general_update_args = {
            method => "update",
            params => {
                sid      => $general_sid,
                id       => $general_id,
                password => 'info2',
            }
        };
        my $update_msg = $obj->run($general_update_args)->{error}->{message};
        ok( $update_msg, "error update" );
    };
    subtest 'delete' => sub {
        my $loginid    = $sample->{loginid};
        my $get_params = { loginid => $loginid, sid => $sid };
        my $get_args   = { method  => "get", params => $get_params };
        my $id   = $obj->run($get_args)->{id};
        my $args = { method => "delete", params => { id => $id, sid => $sid } };
        my $hash = $obj->run($args);
        ok( !%{$hash}, 'delete' );
        my $error = $obj->run($get_args)->{error};
        ok( $error->{message}, 'delete' );
        my $delete_args = {
            method => "delete",
            params => { id => $general_id, sid => $general_sid }
        };
        my $delete_msg = $obj->run($delete_args)->{error}->{message};
        ok( $delete_msg, "error delete" );
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
    my $sample       = +{ loginid => 'info@becom.co.jp', password => "info" };
    my $sample_limit = +{ limitation => "100" };
    subtest 'signup to end' => sub {
        my $signup_params = +{ %{$sample}, %{$sample_limit} };
        my $args          = { method => "signup", params => $signup_params };
        my $sid           = $obj->run($args)->{sid};
        my $status_args   = { method => "status", params => { sid => $sid } };
        my $login_status  = $obj->run($status_args)->{status};
        like( $login_status, qr/200/, 'success login status' );
        $obj->run( { method => "end", params => { sid => $sid } } );
        my $logout_status = $obj->run($status_args)->{status};
        like( $logout_status, qr/400/, 'success logout' );
    };
    subtest 'start to end' => sub {
        my $start      = $obj->run( { method => "start", params => $sample, } );
        my $sid        = $start->{sid};
        my $decode_sid = decode_base64($sid);
        like( $decode_sid, qr/$sample->{loginid}/, 'success sid' );
        my $user = $start->{user};
        is( $user->{loginid},    $sample->{loginid}, 'success loginid' );
        is( $user->{limitation}, $sample_limit->{limitation}, 'success limit' );
        my $status_args = { method => "status", params => { sid => $sid } };
        my $status      = $obj->run($status_args)->{status};
        like( $status, qr/200/, 'success login status' );
        $obj->run( { method => "end", params => { sid => $sid } } );
        my $logout_status = $obj->run($status_args)->{status};
        like( $logout_status, qr/400/, 'success logout' );
    };
    subtest 'Duplicate login' => sub {
        my $args = { method => "start", params => $sample, };
        my $sid  = $obj->run($args)->{sid};
        my $sid2 = $obj->run($args)->{sid};
        is( $sid, $sid2, "login" );
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
        my $refresh     = $obj->run($refrsh_args);
        my $sid2        = $refresh->{sid};
        ok( $sid2, "ok refresh" );
        isnt( $sid1, $sid2, "Not duplicate" );
        my $user = $refresh->{user};
        is( $user->{loginid},    $sample->{loginid}, 'success loginid' );
        is( $user->{limitation}, $sample_limit->{limitation}, 'success limit' );
        $obj->run( { method => "end", params => { sid => $sid2 } } );
    };
    subtest 'loginid logout' => sub {
        my $start_args = { method => "start", params => $sample, };
        my $sid        = $obj->run($start_args)->{sid};
        ok( $sid, "ok login" );
        my $end_args =
          { method => "end", params => { loginid => $sample->{loginid} } };
        my $status = $obj->run($end_args)->{status};
        is( $status, '200', "logout" );
    };
    subtest 'seek' => sub {
        my $ok_id = $sample->{loginid};
        my $args  = { method => "seek", params => +{ loginid => $ok_id } };
        my $seek  = $obj->run($args);
        is( $seek->{loginid}, $ok_id, 'success loginid' );
        is( $seek->{status},  200,    'success limit' );
        my $ng_id   = 'ngid@becom.co.jp';
        my $ng_args = { method => "seek", params => +{ loginid => $ng_id } };
        my $ng_seek = $obj->run($ng_args);
        is( $ng_seek->{loginid}, $ng_id, 'success loginid' );
        is( $ng_seek->{status},  400,    'success limit' );
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

Beauth::CGI については手動による動作確認にしておく

local server example
python3 -m http.server 8000 --cgi

local client example
curl 'http://localhost:8000/cgi-bin/sample.cgi'

curl 'http://localhost:8000/cgi-bin/index.cgi' \
--verbose \
--header 'Content-Type: application/json' \
--header 'accept: application/json' \
--data-binary '{}'

See documentation, location here `doc/`
