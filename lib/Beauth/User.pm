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

sub _valid {
    my ( $self, @args ) = @_;
    my $params = shift @args;

    # root 権限のみ有効
    my $sid = $params->{sid};
    return $self->error->commit("not exist sid") if !$sid;
    my $sid_to_loginid = $self->sid_to_loginid( { sid => $sid } );
    return $self->error->commit("not exist sid: $sid") if !$sid_to_loginid;
    my $is_root = $self->is_root( { loginid => $sid_to_loginid } );
    return $self->error->commit("Unauthorized") if !$is_root;
    return;
}

sub _list {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};

    # root 権限のみ有効
    return if $self->_valid($params);
    my $table = 'user';
    my $rows  = $self->valid_search( $table, {} );
    return $self->error->commit("not exist $table: ") if !$rows;
    return $rows;
}

sub _delete {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};

    # root 権限のみ有効
    return if $self->_valid($params);
    my $id     = $params->{id};
    my $table  = 'user';
    my $update = $self->safe_update( $table, { id => $id }, { deleted => 1 } );
    return $self->error->commit("not exist $table id: $id") if !$update;
    return {};
}

sub _update {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};

    # root 権限のみ有効
    return if $self->_valid($params);
    my $id       = $params->{id};
    my $password = $params->{password};
    my $table    = 'user';
    my $update =
      $self->safe_update( $table, { id => $id }, { password => $password } );
    return $self->error->commit("not exist $table id: $id") if !$update;
    return $update;
}

sub _insert {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};

    # root 権限のみ有効
    return if $self->_valid($params);
    my $table    = 'user';
    my $loginid  = $params->{loginid};
    my $password = $params->{password};
    my $row      = $self->valid_single( $table, { loginid => $loginid } );
    return $self->error->commit("exist $table: $loginid") if $row;
    my $create = $self->safe_insert( $table,
        +{ loginid => $loginid, password => $password, approved => 1, } );
    my $limitation = $self->safe_insert( 'limitation',
        +{ loginid => $loginid, status => $params->{limitation} || '200', } );
    return $create;
}

sub _get {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};

    # root 権限のみ有効
    return if $self->_valid($params);
    my $table   = 'user';
    my $loginid = $params->{loginid};
    my $row     = $self->valid_single( $table, { loginid => $loginid } );
    return $self->error->commit("not exist user: $loginid") if !$row;
    return $row;
}

1;

__END__
