package Beauth::DB;
use strict;
use warnings;
use utf8;
use parent 'SQLite::Simple';

sub db {
    my ( $self, $args ) = @_;
    my $simple = SQLite::Simple->new(
        {
            db_file_path  => 'db/sample.db',
            sql_file_path => 'sample.sql',
            %{$args},
        }
    );
    return $simple;
}

1;

__END__
