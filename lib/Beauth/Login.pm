package Beauth::Login;
use parent 'Beauth';
use strict;
use warnings;
use utf8;
use MIME::Base64;

sub run {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    return $self->error->commit("No arguments") if !$options;
    return $self->_start($options)  if $options->{method} eq 'start';
    return $self->_status($options) if $options->{method} eq 'status';
    return $self->_end($options)    if $options->{method} eq 'end';

    # return $self->_insert($options) if $options->{method} eq 'insert';
    # return $self->_update($options) if $options->{method} eq 'update';
    # return $self->_delete($options) if $options->{method} eq 'delete';
    # return $self->_list($options)   if $options->{method} eq 'list';
    return $self->error->commit(
        "Method not specified correctly: $options->{method}");
}

sub _exists_history {
    my ( $self, @args ) = @_;
    my $loginid = shift @args;
    my $params  = { loginid => $loginid };
    return $self->single( 'login', ['loginid'], $params );
}

sub _update_login {
    my ( $self, @args ) = @_;
    my $row        = shift @args;
    my $expiry_ts  = $self->ts_10_days_later;
    my $loginid    = $row->{loginid};
    my $sid        = encode_base64( "$loginid:$expiry_ts", '' );
    my $update_row = { table => 'login', row => $row };
    my $set_args   = [ [ 'loggedin', 'sid' ], { loggedin => 1, sid => $sid } ];
    my $where_args = [ ['id'], { id => $row->{id} } ];
    my $update     = $self->db_update( $update_row, $set_args, $where_args );
    return $update;
}

sub _start {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $loginid = $params->{loginid};
    my $row     = $self->single( 'user', [ 'loginid', 'password' ], $params );
    return $self->error->commit("not exist user: $loginid") if !$row;

    # 過去のログイン履歴
    if ( my $row = $self->_exists_history($loginid) ) {
        return $self->error->commit("You are logged in: $loginid")
          if $row->{loggedin};

        # 履歴がある場合はアップデートでおこなう
        my $update = $self->_update_login($row);
        return { sid => $update->{sid} };
    }
    my $expiry_ts = $self->ts_10_days_later;
    my $dt        = $self->time_stamp;
    my $sid       = encode_base64( "$loginid:$expiry_ts", '' );
    my $cols      = [
        'sid',     'loginid',    'loggedin', 'expiry_ts',
        'deleted', 'created_ts', 'modified_ts',
    ];
    my $data   = [ $sid, $loginid, 1, $expiry_ts, 0, $dt, $dt ];
    my $create = $self->db_insert( 'login', $cols, $data );
    return { sid => $create->{sid} };
}

sub _status {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $table   = 'login';
    my $sid     = $params->{sid};
    my $row     = $self->single( $table, [ 'sid', 'loggedin' ], $params );
    return { status => 400 } if !$row;
    return { status => 200, sid => $row->{sid} };
}

sub _end {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $sid     = $params->{sid};
    my $row     = $self->single( 'login', ['sid'], $params );
    return $self->error->commit("not exist sid: $sid") if !$row;
    my $update_row = { table => 'login', row => $row };
    my $set_args   = [ ['loggedin'], { loggedin => 0 } ];
    my $where_args = [ ['id'],       { id       => $row->{id} } ];
    my $update     = $self->db_update( $update_row, $set_args, $where_args );
    return {};
}

1;

__END__
