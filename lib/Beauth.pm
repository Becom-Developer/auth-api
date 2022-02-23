package Beauth;
use strict;
use warnings;
use utf8;
use FindBin;
use JSON::PP;
use File::Spec;
use DBI;
use Time::Piece;
use Data::Dumper;
use Beauth::Build;
use Beauth::Error;

sub new   { bless {}, shift; }
sub build { Beauth::Build->new }
sub error { Beauth::Error->new }

1;

__END__
