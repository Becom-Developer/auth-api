package Beauth::User;
use parent 'Beauth';
use strict;
use warnings;
use utf8;

sub run {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    return $self->error->commit("No arguments") if !$options;
    return $self->_get($options)                if $options->{method} eq 'get';
    return $self->_insert($options) if $options->{method} eq 'insert';
    return $self->_update($options) if $options->{method} eq 'update';
    return $self->_delete($options) if $options->{method} eq 'delete';
    return $self->_list($options)   if $options->{method} eq 'list';
    return $self->error->commit(
        "Method not specified correctly: $options->{method}");
}

sub _list {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $table   = 'user';
    my $rows    = $self->rows( $table, [], {} );
    return $self->error->commit("not exist $table: ") if @{$rows} eq 0;
    return $rows;
}

sub _delete {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $id      = $params->{id};
    my $table   = 'user';
    my $row     = $self->single( $table, ['id'], $params );
    return $self->error->commit("not exist $table id: $id") if !$row;
    my $update_row = { table => $table, row => $row };
    my $set_args   = [ ['deleted'], { deleted => 1 } ];
    my $update     = $self->db_update( $update_row, $set_args );
    return {};
}

sub _update {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $table   = 'user';
    my $row     = $self->single( $table, ['id'], $params );
    return $self->error->commit("not exist $table id: $params->{id}") if !$row;
    my $update_row = { table => $table, row => $row };
    my $set_args   = [ [ 'loginid', 'password' ], $params ];
    my $update     = $self->db_update( $update_row, $set_args );
    return $update;
}

sub _insert {
    my ( $self, @args ) = @_;
    my $options  = shift @args;
    my $params   = $options->{params};
    my $table    = 'user';
    my $loginid  = $params->{loginid};
    my $password = $params->{password};
    my $row      = $self->single( $table, ['loginid'], $params );
    return $self->error->commit("exist $table: $loginid") if $row;
    my $cols   = [ 'loginid', 'password', 'approved' ];
    my $data   = [ $loginid, $password, 1 ];
    my $create = $self->db_insert( $table, $cols, $data );
    return $create;
}

sub _get {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $table   = 'user';
    my $loginid = $params->{loginid};
    my $row     = $self->single( $table, ['loginid'], $params );
    return $self->error->commit("not exist user: $loginid") if !$row;
    return $row;
}

1;

__END__
