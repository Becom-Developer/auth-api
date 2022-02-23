package Beauth::Render;
use parent 'Beauth';
use strict;
use warnings;
use utf8;
use Encode qw(encode decode);
use JSON::PP;

sub raw {
    my ( $self, @args ) = @_;
    print encode( 'UTF-8', shift @args );
    return;
}

sub all_items_json {
    my ( $self, @args ) = @_;
    my $params = shift @args;
    print encode_json($params);
    print "\n";
    return;
}

1;
