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

subtest 'build insert dump restore' => sub {
    my $tmp_db = File::Temp->new(
        TEMPLATE => 'sampleXXXXX',
        DIR      => "$FindBin::RealBin/",
        SUFFIX   => '.db',
        EXLOCK   => 0,
        UNLINK   => 1,
    );
    my $db       = $tmp_db->filename;
    my $tmp_dump = File::Temp->new(
        TEMPLATE => 'sampleXXXXX',
        DIR      => "$FindBin::RealBin/",
        SUFFIX   => '.dump',
        EXLOCK   => 0,
        UNLINK   => 1,
    );
    my $dump = $tmp_dump->filename;
    my $args = +{
        db_file_path   => $db,
        sql_file_path  => "$FindBin::RealBin/test.sql",
        dump_file_path => $dump,
    };
    my $obj       = new_ok( 'SQLite::Simple' => [$args] );
    my $build_msg = $obj->build();
    like( $build_msg->{message}, qr/success/, 'success init' );
    like( $build_msg->{message}, qr/sample/,  'success init' );
    my $params = +{
        csv   => "$FindBin::RealBin/test.csv",
        table => 'user',
        cols  => [
            'loginid',    'password', 'approved', 'deleted',
            'created_ts', 'modified_ts',
        ],
        time_stamp => [ 'created_ts', 'modified_ts', ],
    };
    my $insert_msg = $obj->build_insert($params);
    like( $insert_msg->{message}, qr/success/, 'success insert' );
    my $dump_msg = $obj->build_dump();
    like( $dump_msg->{message}, qr/success/, 'success dump' );
    my $restore = $obj->build_restore();
    like( $restore->{message}, qr/success/, 'success restore' );
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
