#!/usr/bin/perl
use strict;
use warnings;

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

while(<MATRIX>) {
    chomp;
    my @input = split("\t");
    my $title = shift(@input);
    my (undef,undef,undef,$st,$en) = split("~", $title);
    my $len = $en - $st;

    my ($sum, $mean, $variance) = (0, 0, 0);
    for my $i (0..$#input) {
	$sum += $input[$i];
	$mean += $i * $input[$i];
	$variance += $i * $input[$i] * $input[$i];
    }
    unless ($sum == 0) {
	$mean = $mean / $sum; $variance = $variance / $sum;
	$variance -= $mean * $mean;
    }
    
    print join("\t", $title, $len, $sum, $mean, $variance), "\n";
}
close(MATRIX);

0;
