package SQLite::Simple;
use strict;
use warnings;
use utf8;
use DBI;
use Data::Dumper;

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

1;

__END__
