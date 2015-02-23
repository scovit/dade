#!/usr/bin/perl
use strict;
use warnings;

use Statistics::Descriptive;

# Takes as input matrix, output a vector
# Basically a oneliner, but since we have colsum ....

if ($#ARGV != 0) {
    print STDERR "usage: ./rowsum.pl matrix\n";
    exit;
}
my $matrixfn = shift @ARGV;

# open input files
if ($matrixfn eq '-') {
    *MATRIX = *STDIN;
} elsif ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

# output, stdout
$stat = Statistics::Descriptive::Full->new();

while(<MATRIX>) {
    chomp;
    my @input = split("\t");
    my $title = shift(@input);

    $stat->add_data(@input);
    print join("\t", $title, $len, $stat->sum(), $stat->mean()
	       , $stat->variance(), $stat->variance()
	       , $stat->quantile(0), $stat->quantile(1), $stat->quantile(2)
	       , $stat->quantile(3), $stat->quantile(4)), "\n";

    $stat->clear();
}
close(MATRIX);

0;
