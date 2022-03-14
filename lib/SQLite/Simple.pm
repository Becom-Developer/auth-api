package SQLite::Simple;
use strict;
use warnings;
use utf8;
use DBI;
use Data::Dumper;
use Time::Piece;
use Text::CSV;
use File::Path qw(make_path remove_tree);
use File::Basename;

sub new {
    my $class = shift;
    my $args  = shift || {};
    return bless $args, $class;
}

sub db_file_path   { shift->{db_file_path}; }
sub sql_file_path  { shift->{sql_file_path}; }
sub dump_file_path { shift->{dump_file_path}; }
sub time_stamp     { localtime->datetime( 'T' => ' ' ); }

sub build_dbh {
    my ( $self, @args ) = @_;
    my $db   = $self->db_file_path;
    my $attr = +{
        RaiseError     => 1,
        AutoCommit     => 1,
        sqlite_unicode => 1,
    };
    my $dbh = DBI->connect( "dbi:SQLite:dbname=$db", "", "", $attr );
    return $dbh;
}

sub build {
    my ( $self, @args ) = @_;
    my $db      = $self->db_file_path;
    my $sql     = $self->sql_file_path;
    my $db_file = basename($db);
    die "not file: $!: $sql" if !-e $sql;
    my $dirname = dirname($db);
    if ( !-d $dirname ) {
        make_path($dirname);
    }

    # example: sqlite3 sample.db < sample.sql
    my $cmd = "sqlite3 $db < $sql";
    system $cmd and die "Couldn'n run: $cmd ($!)";
    return +{ message => qq{build success $db_file} };
}

sub build_insert {
    my ( $self, @args ) = @_;
    my $params = shift @args;
    my $path   = $params->{csv};
    my $fh     = IO::File->new( $path, "<:encoding(utf8)" );
    die "not file: $!" if !$fh;
    my $cols = $params->{cols};
    my $col  = join( ',', @{$cols} );
    my $q    = [];

    for my $int ( @{$cols} ) {
        push( @{$q}, '?' );
    }
    my $table  = $params->{table};
    my $values = join( ',', @{$q} );
    my $sql    = qq{INSERT INTO $table ($col) VALUES ($values)};
    my $dbh    = $self->build_dbh;
    my $csv    = Text::CSV->new();

    # time stamp の指定
    my $stamp_cols = $params->{time_stamp};
    my $stamp_int  = [];
    my $int        = 0;
    for my $col ( @{$cols} ) {
        if ( grep { $_ eq $col } @{$stamp_cols} ) {
            push @{$stamp_int}, $int;
        }
        $int += 1;
    }
    my $dt = $self->time_stamp;
    while ( my $row = $csv->getline($fh) ) {
        my $data = $row;
        if ($stamp_cols) {
            for my $int ( @{$stamp_int} ) {
                $data->[$int] = $dt;
            }
        }
        my $sth = $dbh->prepare($sql);
        $sth->execute( @{$data} ) or die $dbh->errstr;
    }
    $fh->close;
    return +{ message => qq{insert success $path} };
}

sub build_dump {
    my ( $self, @args ) = @_;
    my $db        = $self->db_file_path;
    my $dump      = $self->dump_file_path;
    my $dump_file = basename($dump);

    die "not file: $!: $db" if !-e $db;

    # 例: sqlite3 sample.db .dump > sample.dump
    my $cmd = "sqlite3 $db .dump > $dump";
    system $cmd and die "Couldn'n run: $cmd ($!)";
    return +{ message => qq{dump success $dump_file} };
}

sub build_restore {
    my ( $self, @args ) = @_;
    my $db      = $self->db_file_path;
    my $dump    = $self->dump_file_path;
    my $db_file = basename($db);
    die "not file: $!: $dump" if !-e $dump;
    if ( -e $db ) {
        unlink $db;
    }

    # example: sqlite3 sample.db < sample.dump
    my $cmd = "sqlite3 $db < $dump";
    system $cmd and die "Couldn'n run: $cmd ($!)";
    return +{ message => qq{restore success $db_file} };
}

1;

__END__
