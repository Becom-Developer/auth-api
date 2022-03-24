package Beauth::CLI;
use parent 'Beauth';
use strict;
use warnings;
use utf8;
use Encode qw(encode decode);
use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Beauth::Render;
sub render { return Beauth::Render->new; }

sub run {
    my ( $self, @args ) = @_;
    my $resource = shift @args;
    my $method   = shift @args;
    return $self->error->output("Resource specification does not exist")
      if !$resource;
    return $self->error->output("Method specification does not exist")
      if !$method;
    my $params = '{}';
    GetOptionsFromArray( \@args, "params=s" => \$params, )
      or die("Error in command line arguments\n");
    my $opt = +{
        resource => decode( 'UTF-8', $resource ),
        method   => decode( 'UTF-8', $method ),
        params   => decode_json($params),
    };
    if ( $opt->{resource} eq 'build' ) {
        $self->render->all_items_json( $self->build->start($opt) );
        return;
    }
    if ( $opt->{resource} eq 'user' ) {
        $self->render->all_items_json( $self->user->run($opt) );
        return;
    }
    if ( $opt->{resource} eq 'login' ) {
        $self->render->all_items_json( $self->login->run($opt) );
        return;
    }
    if ( $opt->{resource} eq 'webapi' ) {
        $self->render->all_items_json( $self->webapi->run($opt) );
        return;
    }
    return $self->error->output(
        "Resources and methods are not specified correctly");
}

1;

__END__
