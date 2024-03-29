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
    return $self->_seek($options)    if $options->{method} eq 'seek';
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
    my $row      = $self->valid_single( $table, { loginid => $loginid } );
    return $self->error->commit("exist $table: $loginid")    if $row;
    return $self->error->commit("error loginid: $loginid")   if !$loginid;
    return $self->error->commit("error password: $password") if !$password;

    my $limit = $params->{limitation};
    if ($limit) {
        return $self->error->commit("error limitation: $limit")
          if ( $limit ne 100 ) && ( $limit ne 200 );
    }
    my $create = $self->safe_insert( $table,
        +{ loginid => $loginid, password => $password, approved => 1, } );
    my $expiry_ts = $self->ts_10_days_later;
    my $sid       = $self->session_id($loginid);
    my $login     = $self->safe_insert(
        'login',
        +{
            sid       => $sid,
            loginid   => $loginid,
            loggedin  => 1,
            expiry_ts => $expiry_ts
        }
    );
    my $limitation = $self->safe_insert( 'limitation',
        +{ loginid => $loginid, status => $limit || '200', } );
    return {
        sid  => $login->{sid},
        user => { loginid => $loginid, limitation => $limitation->{status} }
    };
}

sub _refresh {
    my ( $self, @args ) = @_;
    my $options        = shift @args;
    my $params         = $options->{params};
    my $sid            = $params->{sid};
    my $sid_to_loginid = $self->sid_to_loginid( { sid => $sid } );
    return $self->error->commit("not exist sid: $sid") if !$sid_to_loginid;
    my $expiry_ts = $self->ts_10_days_later;
    my $new_sid   = $self->session_id($sid_to_loginid);
    my $update    = $self->safe_update(
        'login',
        { sid => $sid, loggedin => 1, },
        { loggedin => 1, sid => $new_sid, expiry_ts => $expiry_ts, }
    );
    my $loginid = $update->{loginid};
    my $limitation =
      $self->valid_single( 'limitation', { loginid => $loginid } );
    return $self->error->commit("not exist sid: $sid") if !$update;
    return {
        sid  => $update->{sid},
        user => { loginid => $loginid, limitation => $limitation->{status} }
    };
}

sub _start {
    my ( $self, @args ) = @_;
    my $options  = shift @args;
    my $params   = $options->{params};
    my $loginid  = $params->{loginid};
    my $q_params = { loginid => $loginid, password => $params->{password}, };
    my $row      = $self->valid_single( 'user', $q_params );
    return $self->error->commit("not exist user: $loginid") if !$row;

    # 過去のログイン履歴
    my $sid       = $self->session_id($loginid);
    my $expiry_ts = $self->ts_10_days_later;
    my $login     = $self->valid_single( 'login', { loginid => $loginid } );
    my $limitation =
      $self->valid_single( 'limitation', { loginid => $loginid } );
    if ($login) {
        return { sid => $login->{sid} } if $login->{loggedin};

        # 履歴がある場合はアップデートでおこなう
        my $update = $self->safe_update(
            'login',
            { loginid  => $loginid },
            { loggedin => 1, sid => $sid, expiry_ts => $expiry_ts, }
        );
        return {
            sid  => $update->{sid},
            user => { loginid => $loginid, limitation => $limitation->{status} }
        };
    }
    my $create = $self->safe_insert(
        'login',
        +{
            sid       => $sid,
            loginid   => $loginid,
            loggedin  => 1,
            expiry_ts => $expiry_ts,
        }
    );
    return {
        sid  => $create->{sid},
        user => { loginid => $loginid, limitation => $limitation->{status} }
    };
}

sub _status {
    my ( $self, @args ) = @_;
    my $options  = shift @args;
    my $params   = $options->{params};
    my $q_params = { sid => $params->{sid}, loggedin => "1", };
    my $row      = $self->valid_single( 'login', $q_params );
    return { status => 400 } if !$row;
    my $loginid = $row->{loginid};
    my $limitation =
      $self->valid_single( 'limitation', { loginid => $loginid } );
    return {
        status => 200,
        sid    => $row->{sid},
        user   => { loginid => $loginid, limitation => $limitation->{status} }
    };
}

sub _end {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $sid     = $params->{sid};
    if ($sid) {
        my $row =
          $self->safe_update( 'login', { sid => $sid }, { loggedin => 0 } );
        return $self->error->commit("not exist sid: $sid") if !$row;
        return { status => 200 };
    }
    my $loginid = $params->{loginid};
    if ($loginid) {
        my $row = $self->safe_update(
            'login',
            { loginid  => $loginid },
            { loggedin => 0 }
        );
        return $self->error->commit("not exist loginid: $loginid") if !$row;
        return { status => 200 };
    }
    return { status => 400 };
}

sub _seek {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $loginid = $params->{loginid};
    my $login   = $self->valid_single( 'login', { loginid => $loginid } );
    return { status => 400, loginid => $loginid, } if !$login;
    return { status => 200, loginid => $loginid, };
}

1;

__END__
