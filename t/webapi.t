use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Test::Trap qw/:die :output(systemsafe)/;
use JSON::PP;
use Beauth;
use File::Spec;
use File::Temp qw/ tempfile tempdir /;
my $temp     = File::Temp->newdir( DIR => $FindBin::RealBin, CLEANUP => 1, );
my $test_dir = $temp->dirname;
$ENV{"BEAUTH_MODE"} = 'test';
$ENV{"BEAUTH_DUMP"} = File::Spec->catfile( $test_dir, 'beauth.dump' );
$ENV{"BEAUTH_DB"}   = File::Spec->catfile( $test_dir, 'beauth.db' );

subtest 'Webapi' => sub {
    new_ok('Beauth::Build')->start( { method => 'init' } );
    my $obj = new_ok('Beauth::Webapi');
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
    my $sample = +{ loginid => 'info@becom.co.jp', password => "info" };
    subtest 'issue to delete' => sub {
        my $args = +{
            method => "issue",
            params => { sid => $sid, target => "zsearch", }
        };
        my $hash = $obj->run($args);
        ok( $hash->{apikey}, 'issue' );
        is( $hash->{sid}, $sid, 'issue' );
        my $delete_args = +{
            method => "delete",
            params => { sid => $sid, apikey => $hash->{apikey}, }
        };
        my $delete = $obj->run($delete_args);
        is( $delete->{sid}, $sid, 'delete' );
        my $try_issue = $obj->run($args);
        ok( $try_issue->{apikey}, 'delete' );
        isnt( $try_issue->{apikey}, $hash->{apikey}, 'delete' );
        is( $try_issue->{sid}, $sid, 'delete' );
        my $list_args = +{ method => "list", params => { sid => $sid } };
        my $list      = $obj->run($list_args);
        is( $list->{sid},                 $sid,                 'list' );
        is( $list->{list}->[0]->{apikey}, $try_issue->{apikey}, 'list' );
    };
    subtest 'script webapi' => sub {
        my $script =
          File::Spec->catfile( $FindBin::RealBin, '..', 'script', 'beauth' );
        my $params = { sid => $sid, target => "mhj", };
        my $bytes  = encode_json($params);
        trap { system "$script webapi issue --params='$bytes'" };
        my $chars = decode_json( $trap->stdout );
        ok( $chars->{sid},    "ok issue" );
        ok( $chars->{apikey}, "ok issue" );
        my $list_params = +{ sid => $sid };
        my $bytes_list  = encode_json($list_params);
        trap { system "$script webapi list --params='$bytes_list'" };
        my $chars_list = decode_json( $trap->stdout );
        ok( $chars_list->{sid},  "ok list" );
        ok( $chars_list->{list}, "ok list" );
        my $delete_params = +{ sid => $sid, apikey => $chars->{apikey} };
        my $delete_list   = encode_json($delete_params);
        trap { system "$script webapi delete --params='$delete_list'" };
        my $chars_delete = decode_json( $trap->stdout );
        ok( $chars_delete->{sid}, "ok delete" );
    };
};

done_testing;

__END__
