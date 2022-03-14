use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Beauth;
use File::Temp qw/ tempfile tempdir /;
my $temp = File::Temp->newdir(
    DIR     => $FindBin::RealBin,
    CLEANUP => 1,
);
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
};

done_testing;

__END__
