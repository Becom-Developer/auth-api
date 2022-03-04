use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Beauth;
$ENV{"BEAUTH_MODE"} = 'test';

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
        is( $delete->{sid}, $sid, 'issue' );
        my $try_issue = $obj->run($args);
        ok( $try_issue->{apikey}, 'issue' );
        isnt( $try_issue->{apikey}, $hash->{apikey}, 'issue' );
        is( $try_issue->{sid}, $sid, 'issue' );
    };
};

done_testing;

__END__
