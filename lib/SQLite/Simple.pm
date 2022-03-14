package SQLite::Simple;
use strict;
use warnings;
use utf8;
use DBI;
use Data::Dumper;
use File::Path qw(make_path remove_tree);
use File::Basename;

# sub new { bless {}, shift; }

sub new {
    my $class = shift;
    my $args  = shift || {};
    return bless $args, $class;
}

sub db_file_path  { shift->{db_file_path}; }
sub sql_file_path { shift->{sql_file_path}; }

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

    # for example: sqlite3 sample.db < sample.sql
    my $cmd = "sqlite3 $db < $sql";
    system $cmd and die "Couldn'n run: $cmd ($!)";
    return +{ message => qq{build success $db_file} };
}

1;

__END__
