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
    return $self->_list($options)   if $options->{method} eq 'list';
    return $self->error->commit(
        "Method not specified correctly: $options->{method}");
}

sub _delete {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $table   = 'webapi';
    my $update = $self->safe_update(
        $table,
        { apikey       => $params->{apikey} },
        { is_available => 0 }
    );
    return $self->error->commit("not exist $table apikey:") if !$update;
    return { sid => $params->{sid} };
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

    # apikey履歴がある場合はアップデート
    my $webapi = $self->valid_single( 'webapi',
        { loginid => $loginid, target => $target } );
    my $apikey    = $self->apikey( $loginid, $target );
    my $expiry_ts = $self->ts_10_days_later;
    if ($webapi) {
        my $update = $self->safe_update(
            'webapi',
            { loginid => $loginid, target => $target },
            { apikey  => $apikey,  is_available => 1, expiry_ts => $expiry_ts }
        );
        return { sid => $params->{sid}, apikey => $update->{apikey} };
    }

    # apikey発行
    my $create = $self->safe_insert(
        'webapi',
        +{
            apikey       => $apikey,
            loginid      => $loginid,
            target       => $target,
            is_available => 1,
            expiry_ts    => $expiry_ts,
        }
    );
    return { sid => $params->{sid}, apikey => $create->{apikey} };
}

sub _list {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    my $params  = $options->{params};
    my $loginid = $self->sid_to_loginid($params);
    my $table   = 'webapi';
    my $rows    = $self->valid_search( $table, {} );
    return $self->error->commit("not exist $table: ") if !$rows;
    return +{
        sid  => $params->{sid},
        list => $rows,
    };
}

1;

__END__
