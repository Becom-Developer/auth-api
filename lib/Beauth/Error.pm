package Beauth::Error;
use parent 'Beauth';
use strict;
use warnings;
use utf8;
use Beauth::Render;
sub render { return Beauth::Render->new; }

sub output {
    my ( $self, @args ) = @_;
    my $params = $self->commit( shift @args );
    $self->render->all_items_json($params);
    return;
}

sub commit {
    my ( $self, @args ) = @_;
    my $msg = shift @args;
    return { error => { message => $msg } };
}

1;

__END__

{
  "error": {
    "message": "Not specified correctly"
  }
}
