use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Data::Dumper;
use SQLite::Simple;
$ENV{"BEAUTH_MODE"} = 'test';

subtest 'Class and Method' => sub {
    new_ok('SQLite::Simple');
};

subtest 'args' => sub {
    my $obj = new_ok(
        'SQLite::Simple' => [
            { db_file_path => 'db/sample.db', sql_file_path => 'sample.sql', }
        ]
    );
    is( $obj->db_file_path,  'db/sample.db', "db_file_path" );
    is( $obj->sql_file_path, 'sample.sql',   "sql_file_path" );
};

done_testing;

__END__

package Beauth::DB;
use parent 'SQLite::Simple';

sub db {
  my ($self, $args) = @_;
  my $simple = SQLite::Simple->new({
    db_file_path => 'db/sample.db',
    sql_file_path => 'sample.sql',
    %{$args},
  });
  return $simple;
}

# $self->db->build();
# $self->db->build_insert();
# $self->db->build_dump();
# $self->db->build_restore();

# $self->db->insert($table, \%params);
# $self->db->single($table, \%params);
# $self->db->search($table, \%params);
# $self->db->update($table, \%params);
# my $row = $self->db->row($table, \%params);
# $row->update(\%params);