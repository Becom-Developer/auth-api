package Beauth::Webapi;
use parent 'Beauth';
use strict;
use warnings;
use utf8;

sub run {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    return $self->error->commit("No arguments") if !$options;
    return $self->_issue($options)  if $options->{method} eq 'issue';
    return $self->_delete($options) if $options->{method} eq 'delete';
    return $self->error->commit(
        "Method not specified correctly: $options->{method}");
}

sub _delete {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $table   = 'webapi';
    my $row     = $self->single( $table, ['apikey'], $params );
    return $self->error->commit("not exist $table apikey:") if !$row;
    my $update_row = { table => $table, row => $row };
    my $set_args   = [ ['is_available'], { is_available => 0 } ];
    my $update     = $self->db_update( $update_row, $set_args );
    return { sid => $params->{sid} };
    return;
}

sub _exists_history {
    my ( $self, @args ) = @_;
    my $loginid = shift @args;
    my $target  = shift @args;
    my $params  = +{ loginid => $loginid, target => $target };
    return $self->single( 'webapi', [ 'loginid', 'target' ], $params );
}

sub _update_webapi {
    my ( $self, @args ) = @_;
    my $row        = shift @args;
    my $loginid    = $row->{loginid};
    my $target     = $row->{target};
    my $apikey     = $self->apikey( $loginid, $target );
    my $update_row = { table => 'webapi', row => $row };
    my $set_args   = [
        [ 'apikey', 'is_available' ],
        { apikey => $apikey, is_available => 1, }
    ];
    my $update = $self->db_update( $update_row, $set_args );
    return $update;
}

sub _issue {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $loginid = $self->sid_to_loginid($params);
    my $target  = $params->{target};
    return $self->error->commit("sid is not specified correctly:") if !$loginid;
    return $self->error->commit("target is not specified correctly:")
      if !$self->is_valid_app($params);

    # apikey発行
    my $apikey = $self->apikey( $loginid, $target );

    # apikey履歴
    if ( my $row = $self->_exists_history( $loginid, $target ) ) {

        # 履歴がある場合はアップデートでおこなう
        my $update = $self->_update_webapi($row);
        return { sid => $params->{sid}, apikey => $update->{apikey} };
    }
    my $expiry_ts = $self->ts_10_days_later;
    my $cols = [ 'apikey', 'loginid', 'target', 'is_available', 'expiry_ts', ];
    my $data = [ $apikey, $loginid, $target, 1, $expiry_ts, ];
    my $create = $self->db_insert( 'webapi', $cols, $data );
    return { sid => $params->{sid}, apikey => $create->{apikey} };
}

# sub _list {
#     my ( $self, @args ) = @_;
#     my $options = shift @args;
#     my $params  = $options->{params};

#     # root 権限のみ有効
#     return if $self->_valid($params);
#     my $table = 'user';
#     my $rows  = $self->rows( $table, [], {} );
#     return $self->error->commit("not exist $table: ") if @{$rows} eq 0;
#     return $rows;
# }

1;

__END__
