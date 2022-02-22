package Beauth::Build;
use parent 'Beauth';
use strict;
use warnings;
use utf8;
use File::Path qw(make_path);
# use Text::CSV;

sub start {
    my ( $self, @args ) = @_;
    my $options = shift @args;
    return $self->error->commit("No arguments") if !$options;

    # # 初期設定時のdbファイル準備
    # return $self->_init()    if $options->{method} eq 'init';
    # return $self->_insert()  if $options->{method} eq 'insert';
    # return $self->_dump()    if $options->{method} eq 'dump';
    # return $self->_restore() if $options->{method} eq 'restore';
    return $self->error->commit(
        "Method not specified correctly: $options->{method}");
}

# sub _init {
#     my ( $self, @args ) = @_;
#     my $db_file = $self->db_file;
#     my $db      = $self->db_file_path;
#     my $sql     = $self->sql_file_path;
#     die "not file: $!: $sql" if !-e $sql;
#     if ( !-e $self->db_dir_path ) {
#         make_path( $self->db_dir_path );
#     }

#     # 例: sqlite3 zsearch.db < zsearch.sql
#     my $cmd = "sqlite3 $db < $sql";
#     system $cmd and die "Couldn'n run: $cmd ($!)";
#     return +{ message => qq{build success $db_file} };
# }

# sub _insert {
#     my ( $self, @args ) = @_;
#     my $path = $self->insert_csv();
#     my $dt   = $self->time_stamp;
#     my $csv  = Text::CSV->new();
#     my $fh   = IO::File->new( $path, "<:encoding(utf8)" );
#     die "not file: $!" if !$fh;

#     my $dbh  = $self->build_dbh;
#     my $cols = [
#         'local_code',    'zipcode_old',
#         'zipcode',       'pref_kana',
#         'city_kana',     'town_kana',
#         'pref',          'city',
#         'town',          'double_zipcode',
#         'town_display',  'city_block_display',
#         'double_town',   'update_zipcode',
#         'update_reason', 'deleted',
#         'created_ts',    'modified_ts',
#     ];
#     my $col = join( ',', @{$cols} );
#     my $q   = [];

#     for my $int ( @{$cols} ) {
#         push( @{$q}, '?' );
#     }
#     my $values = join( ',', @{$q} );
#     my $sql    = qq{INSERT INTO post ($col) VALUES ($values)};
#     while ( my $row = $csv->getline($fh) ) {
#         my @data = (
#             $row->[0],  $row->[1],  $row->[2],  $row->[3],  $row->[4],
#             $row->[5],  $row->[6],  $row->[7],  $row->[8],  $row->[9],
#             $row->[10], $row->[11], $row->[12], $row->[13], $row->[14],
#             0,          $dt,        $dt
#         );
#         my $sth = $dbh->prepare($sql);
#         $sth->execute(@data) or die $dbh->errstr;
#     }
#     $fh->close;
#     return +{ message => qq{insert success $path} };
# }

# sub _dump {
#     my ( $self, @args ) = @_;
#     my $db        = $self->db_file_path;
#     my $dump_file = $self->dump_file;
#     my $dump      = $self->dump_file_path;
#     die "not file: $!: $db" if !-e $db;

#     # 例: sqlite3 zsearch.db .dump > zsearch.dump
#     my $cmd = "sqlite3 $db .dump > $dump";
#     system $cmd and die "Couldn'n run: $cmd ($!)";
#     return +{ message => qq{dump success $dump_file} };
# }

# sub _restore {
#     my ( $self, @args ) = @_;
#     my $db_file = $self->db_file;
#     my $db      = $self->db_file_path;
#     my $dump    = $self->dump_file_path;
#     die "not file: $!: $dump" if !-e $dump;
#     if ( -e $db ) {
#         unlink $db;
#     }

#     # 例: sqlite3 zsearch.db < zsearch.dump
#     my $cmd = "sqlite3 $db < $dump";
#     system $cmd and die "Couldn'n run: $cmd ($!)";
#     return +{ message => qq{restore success $db_file} };
# }

1;

__END__
