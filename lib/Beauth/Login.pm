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

sub _loggedin {
    my ( $self, @args ) = @_;
    my $row = shift @args;
    return 1 if $row->{loggedin};
    return 0;
}

sub _exists_history {
    my ( $self, @args ) = @_;
    my $loginid = shift @args;
    my $params  = { loginid => $loginid };
    my $rows    = $self->rows( 'login', ['loginid'], $params );
    return $rows if $rows;
    return;
}

sub _update_login {
    my ( $self, @args ) = @_;
    my $row        = shift @args;
    my $table      = 'login';
    my $dt         = $self->time_stamp;
    my $set_cols   = [ 'loggedin', 'sid' ];
    my $where_cols = ['id'];
    my $set_q      = [];
    my $expiry_ts  = $self->ts_10_days_later;
    my $loginid    = $row->{loginid};
    my $sid        = encode_base64( "$loginid:$expiry_ts", '' );
    my $set_params = { loggedin => 1, sid => $sid };

    for my $col ( @{$set_cols} ) {
        push @{$set_q}, qq{$col = "$set_params->{$col}"};
    }
    push @{$set_q}, qq{modified_ts = "$dt"};
    my $set_clause = join ",", @{$set_q};
    my $where_q    = [];
    for my $col ( @{$where_cols} ) {
        push @{$where_q}, qq{$col = "$row->{$col}"};
    }
    push @{$where_q}, qq{deleted = "0"};
    my $where_clause = join " AND ", @{$where_q};
    my $sql          = qq{UPDATE $table SET $set_clause WHERE $where_clause};
    my $dbh          = $self->build_dbh;
    my $sth          = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    my $update = $self->single( $table, ['id'], { id => $row->{id} } );
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
    my $rows = $self->_exists_history($loginid);
    if ( @{$rows} ) {
        my $row = shift @{$rows};
        return $self->error->commit("You are logged in: $loginid")
          if $self->_loggedin($row);

        # 履歴がある場合はアップデートでおこなう
        my $update = $self->_update_login($row);
        return { sid => $update->{sid} };
    }
    my $dbh = $self->build_dbh;
    my $col =
      q{sid, loginid, loggedin, expiry_ts, deleted, created_ts, modified_ts};
    my $values    = q{?, ?, ?, ?, ?, ?, ?};
    my $expiry_ts = $self->ts_10_days_later;
    my $dt        = $self->time_stamp;
    my $sid       = encode_base64( "$loginid:$expiry_ts", '' );
    my @data      = ( $sid, $loginid, 1, $expiry_ts, 0, $dt, $dt );
    my $sql       = qq{INSERT INTO login ($col) VALUES ($values)};
    my $sth       = $dbh->prepare($sql);
    $sth->execute(@data) or die $dbh->errstr;
    my $id     = $dbh->last_insert_id( undef, undef, undef, undef );
    my $create = $self->single( 'login', ['id'], { id => $id } );
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
    my $table   = 'login';
    my $sid     = $params->{sid};
    my $row     = $self->single( $table, ['sid'], $params );
    return $self->error->commit("not exist sid: $sid") if !$row;
    my $dt         = $self->time_stamp;
    my $set_cols   = ['loggedin'];
    my $where_cols = ['id'];
    my $set_q      = [];

    for my $col ( @{$set_cols} ) {
        push @{$set_q}, qq{$col = 0};
    }
    push @{$set_q}, qq{modified_ts = "$dt"};
    my $set_clause = join ",", @{$set_q};
    my $where_q    = [];
    for my $col ( @{$where_cols} ) {
        push @{$where_q}, qq{$col = "$row->{$col}"};
    }
    push @{$where_q}, qq{deleted = 0};
    my $where_clause = join " AND ", @{$where_q};
    my $sql          = qq{UPDATE $table SET $set_clause WHERE $where_clause};
    my $dbh          = $self->build_dbh;
    my $sth          = $dbh->prepare($sql);
    $sth->execute() or die $dbh->errstr;
    my $update = $self->single( $table, ['id'], { id => $row->{id} } );
    return {};
}

# sub _list {
#     my ( $self, @args ) = @_;
#     my $options = shift @args;
#     my $table   = 'user';
#     my $rows    = $self->rows( $table, [], {} );
#     return $self->error->commit("not exist $table: ") if @{$rows} eq 0;
#     return $rows;
# }

# sub _delete {
#     my ( $self, @args ) = @_;
#     my $options = shift @args;
#     my $params  = $options->{params};
#     my $id      = $params->{id};
#     my $dt      = $self->time_stamp;
#     my $table   = 'user';
#     my $row     = $self->single( $table, ['id'], $params );
#     return $self->error->commit("not exist $table id: $id") if !$row;
#     my $set_clause = qq{deleted = 1,modified_ts = "$dt"};
#     my $sql        = qq{UPDATE $table SET $set_clause WHERE id = $id};
#     my $dbh        = $self->build_dbh;
#     my $sth        = $dbh->prepare($sql);
#     $sth->execute() or die $dbh->errstr;
#     return {};
# }

# sub _update {
#     my ( $self, @args ) = @_;
#     my $options = shift @args;
#     my $params  = $options->{params};
#     my $table   = 'user';
#     my $dt      = $self->time_stamp;
#     my $row     = $self->single( $table, ['id'], $params );
#     return $self->error->commit("not exist $table id: $params->{id}") if !$row;
#     my $set_cols   = [ 'loginid', 'password' ];
#     my $where_cols = ['id'];
#     my $set_q      = [];

#     for my $col ( @{$set_cols} ) {
#         push @{$set_q}, qq{$col = "$params->{$col}"};
#     }
#     push @{$set_q}, qq{modified_ts = "$dt"};
#     my $set_clause = join ",", @{$set_q};

#     my $where_q = [];
#     for my $col ( @{$where_cols} ) {
#         push @{$where_q}, qq{$col = "$params->{$col}"};
#     }
#     push @{$where_q}, qq{deleted = 0};
#     my $where_clause = join " AND ", @{$where_q};
#     my $sql          = qq{UPDATE $table SET $set_clause WHERE $where_clause};
#     my $dbh          = $self->build_dbh;
#     my $sth          = $dbh->prepare($sql);
#     $sth->execute() or die $dbh->errstr;
#     my $update = $self->single( $table, ['id'], { id => $params->{id} } );
#     return $update;
# }

# sub _insert {
#     my ( $self, @args ) = @_;
#     my $options  = shift @args;
#     my $params   = $options->{params};
#     my $table    = 'user';
#     my $loginid  = $params->{loginid};
#     my $password = $params->{password};
#     my $dt       = $self->time_stamp;
#     my $row      = $self->single( $table, ['loginid'], $params );
#     return $self->error->commit("exist $table: $loginid") if $row;
#     my $dbh = $self->build_dbh;
#     my $col = q{loginid, password, approved, deleted, created_ts, modified_ts};
#     my $values = q{?, ?, ?, ?, ?, ?};
#     my @data   = ( $loginid, $password, 1, 0, $dt, $dt );
#     my $sql    = qq{INSERT INTO $table ($col) VALUES ($values)};
#     my $sth    = $dbh->prepare($sql);
#     $sth->execute(@data) or die $dbh->errstr;
#     my $id     = $dbh->last_insert_id( undef, undef, undef, undef );
#     my $create = $self->single( $table, ['id'], { id => $id } );
#     return $create;
# }

# sub _get {
#     my ( $self, @args ) = @_;
#     my $options = shift @args;
#     my $params  = $options->{params};
#     my $table   = 'user';
#     my $loginid = $params->{loginid};
#     my $row     = $self->single( $table, ['loginid'], $params );
#     return $self->error->commit("not exist user: $loginid") if !$row;
#     return $row;
# }

1;

__END__
