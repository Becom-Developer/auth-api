use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/../lib", "$FindBin::RealBin/../local/lib/perl5" );
use Data::Dumper;
use SQLite::Simple;
use File::Temp qw/ tempfile tempdir /;
use File::Path qw(make_path remove_tree);
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

subtest 'build' => sub {
    my $args = +{
        db_file_path  => "$FindBin::RealBin/../test/sample.db",
        sql_file_path => "$FindBin::RealBin/test.sql",
    };
    my $hash = new_ok( 'SQLite::Simple' => [$args] )->build();
    like( $hash->{message}, qr/success/,   'success init' );
    like( $hash->{message}, qr/sample.db/, 'success init' );
    remove_tree("$FindBin::RealBin/../test/");
};

# my $tmp = File::Temp->new(
#     TEMPLATE => 'sampleXXXXX',
#     DIR      => "$FindBin::RealBin/",
#     SUFFIX   => '.db'
# );
# my $filename = $tmp->filename;
# warn Dumper $filename;
# subtest 'insert' => sub {
#     my $hash = $obj->start(
#         {
#             method => 'insert',
#             params => {
#                 csv   => 'user-test.csv',
#                 table => 'user',
#                 cols  => [
#                     'loginid',    'password', 'approved', 'deleted',
#                     'created_ts', 'modified_ts',
#                 ]
#             }
#         }
#     );
#     like( $hash->{message}, qr/success/, 'success insert' );
# };
# subtest 'dump' => sub {
#     my $hash = $obj->start( { method => 'dump', } );
#     like( $hash->{message}, qr/success/, 'success dump' );
# };
# subtest 'restore' => sub {
#     my $db = $obj->db_file_path;
#     unlink $db;
#     ok( !-e $db, "delete db file" );
#     my $hash = $obj->start( { method => 'restore', } );
#     like( $hash->{message}, qr/success/, 'success restore' );
# };

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
