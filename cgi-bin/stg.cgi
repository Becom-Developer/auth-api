#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use File::Spec;
use Beauth::CGI;
$ENV{"BEAUTH_MODE"} = 'stg';
$ENV{"BEAUTH_DUMP"} =
  File::Spec->catfile( $FindBin::RealBin, '..', 'backup', 'beauth-stg.dump' );
$ENV{"BEAUTH_DB"} =
  File::Spec->catfile( $FindBin::RealBin, '..', 'db', 'beauth-stg.db' );

Beauth::CGI->new->run;

__END__
