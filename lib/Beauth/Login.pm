package Beauth::Login;
use parent 'Beauth';
use strict;
use warnings;
use utf8;

sub run {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    return $self->error->commit("No arguments") if !$options;
    return $self->_signup($options)  if $options->{method} eq 'signup';
    return $self->_start($options)   if $options->{method} eq 'start';
    return $self->_status($options)  if $options->{method} eq 'status';
    return $self->_end($options)     if $options->{method} eq 'end';
    return $self->_refresh($options) if $options->{method} eq 'refresh';
    return $self->error->commit(
        "Method not specified correctly: $options->{method}");
}

sub _signup {
    my ( $self, @args ) = @_;
    my $options  = shift @args;
    my $params   = $options->{params};
    my $table    = 'user';
    my $loginid  = $params->{loginid};
    my $password = $params->{password};
    my $row      = $self->single( $table, ['loginid'], $params );
    return $self->error->commit("exist $table: $loginid") if $row;
    my $cols      = [ 'loginid', 'password', 'approved' ];
    my $data      = [ $loginid, $password, 1 ];
    my $create    = $self->db_insert( $table, $cols, $data );
    my $expiry_ts = $self->ts_10_days_later;
    my $sid       = $self->session_id($loginid);
    my $login     = $self->db_insert(
        'login',
        [ 'sid', 'loginid', 'loggedin', 'expiry_ts', ],
        [ $sid,  $loginid,  1,          $expiry_ts, ]
    );
    my $limitation = $self->db_insert(
        'limitation',
        [ 'loginid', 'status' ],
        [ $loginid,  $params->{limitation} ]
    );
    return { sid => $login->{sid} };
}

sub _refresh {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $sid     = $params->{sid};
    $params->{loggedin} = 1;
    my $row = $self->single( 'login', [ 'sid', 'loggedin' ], $params );
    return $self->error->commit("not exist sid: $sid") if !$row;
    my $update = $self->_update_login($row);
    return { sid => $update->{sid} };
}

sub _exists_history {
    my ( $self, @args ) = @_;
    my $loginid = shift @args;
    return $self->single( 'login', ['loginid'], { loginid => $loginid } );
}

sub _update_login {
    my ( $self, @args ) = @_;
    my $row        = shift @args;
    my $loginid    = $row->{loginid};
    my $sid        = $self->session_id($loginid);
    my $update_row = { table => 'login', row => $row };
    my $set_args   = [ [ 'loggedin', 'sid' ], { loggedin => 1, sid => $sid } ];
    my $update     = $self->db_update( $update_row, $set_args );
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
    my $sid       = $self->session_id($loginid);
    my $cols      = [ 'sid', 'loginid', 'loggedin', 'expiry_ts', ];
    my $data      = [ $sid, $loginid, 1, $expiry_ts, ];
    my $create    = $self->db_insert( 'login', $cols, $data );
    return { sid => $create->{sid} };
}

sub _status {
    my ( $self, @args ) = @_;
    my $options  = shift @args;
    my $params   = $options->{params};
    my $q_params = { %{$params}, loggedin => "1", };
    my $row      = $self->single( 'login', [ 'sid', 'loggedin' ], $q_params );
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
    my $update     = $self->db_update( $update_row, $set_args );
    return {};
}

1;

__END__
