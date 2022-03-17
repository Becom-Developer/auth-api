package Beauth::Build;
use parent 'Beauth';
use strict;
use warnings;
use utf8;
use File::Path qw(make_path);
use Text::CSV;
use File::Basename;

sub start {
    my ( $self, @args ) = @_;
    my $opt = shift @args;
    return $self->error->commit("No arguments") if !$opt;

    # 初期設定時のdbファイル準備
    return $self->_init()       if $opt->{method} eq 'init';
    return $self->_insert($opt) if $opt->{method} eq 'insert';
    return $self->_dump()       if $opt->{method} eq 'dump';
    return $self->_restore()    if $opt->{method} eq 'restore';
    return $self->error->commit(
        "Method not specified correctly: $opt->{method}");
}
sub _init    { shift->db->build(); }
sub _dump    { shift->db->build_dump(); }
sub _restore { shift->db->build_restore(); }

sub _insert {
    my ( $self, @args ) = @_;
    my $opt = shift @args;
    return $self->db->build_insert( $opt->{params} );
}

1;

__END__
