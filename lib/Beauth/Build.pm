package Beauth::Build;
use parent 'Beauth';
use strict;
use warnings;
use utf8;
use File::Path qw(make_path);
use Text::CSV;

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

sub _init {
    my ( $self, @args ) = @_;
    my $db_file = $self->db_file;
    my $db      = $self->db_file_path;
    my $sql     = $self->sql_file_path;
    die "not file: $!: $sql" if !-e $sql;
    if ( !-e $self->homedb ) {
        make_path( $self->homedb );
    }

    # 例: sqlite3 sample.db < sample.sql
    my $cmd = "sqlite3 $db < $sql";
    system $cmd and die "Couldn'n run: $cmd ($!)";
    return +{ message => qq{build success $db_file} };
}

sub _insert {
    my ( $self, @args ) = @_;
    my $opt  = shift @args;
    my $path = $self->insert_csv( $opt->{params}->{csv} );
    my $dt   = $self->time_stamp;
    my $csv  = Text::CSV->new();
    my $fh   = IO::File->new( $path, "<:encoding(utf8)" );
    die "not file: $!" if !$fh;

    my $cols = $opt->{params}->{cols};
    my $col  = join( ',', @{$cols} );
    my $q    = [];

    for my $int ( @{$cols} ) {
        push( @{$q}, '?' );
    }
    my $table  = $opt->{params}->{table};
    my $values = join( ',', @{$q} );
    my $sql    = qq{INSERT INTO $table ($col) VALUES ($values)};
    my $dbh    = $self->build_dbh;
    while ( my $row = $csv->getline($fh) ) {
        my $data = $row;
        push @{$data}, $dt, $dt;
        my $sth = $dbh->prepare($sql);
        $sth->execute( @{$data} ) or die $dbh->errstr;
    }
    $fh->close;
    return +{ message => qq{insert success $path} };
}

sub _dump {
    my ( $self, @args ) = @_;
    my $db        = $self->db_file_path;
    my $dump_file = $self->dump_file;
    my $dump      = $self->dump_file_path;
    die "not file: $!: $db" if !-e $db;

    # 例: sqlite3 sample.db .dump > sample.dump
    my $cmd = "sqlite3 $db .dump > $dump";
    system $cmd and die "Couldn'n run: $cmd ($!)";
    return +{ message => qq{dump success $dump_file} };
}

sub _restore {
    my ( $self, @args ) = @_;
    my $db_file = $self->db_file;
    my $db      = $self->db_file_path;
    my $dump    = $self->dump_file_path;
    die "not file: $!: $dump" if !-e $dump;
    if ( -e $db ) {
        unlink $db;
    }

    # 例: sqlite3 sample.db < sample.dump
    my $cmd = "sqlite3 $db < $dump";
    system $cmd and die "Couldn'n run: $cmd ($!)";
    return +{ message => qq{restore success $db_file} };
}

1;

__END__
