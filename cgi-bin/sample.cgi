#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
my $html = <<"END_HTML";
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="UTF-8">
    <title>hello</title>
  </head>
  <body>
    <h1>hello</h1>
  </body>
</html>
END_HTML

print $html;

__END__
