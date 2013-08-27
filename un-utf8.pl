#!/usr/bin/env perl

use Encode;

my $foo = "";

open(INFILE, $ARGV[0]) || die "error: $!";
while (<INFILE>) {
  $foo .= $_;
}
close(INFILE);

my $out = encode("ascii", $foo);
print $out;
