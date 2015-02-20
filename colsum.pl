#!/usr/bin/perl
use strict;
use warnings;

# Takes as input matrix, output as dense matrix

if ($#ARGV != 0) {
	print "usage: ./colsum.pl matrix\n";
	exit;
};
my ($matrixfn) = @ARGV;

# open input files
if ($matrixfn eq '-') {
    *MATRIX = *STDIN;
} elsif ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

# output, stdout
my @output;

while(<MATRIX>) {
    my $i = $. - 1;
    chomp;
    my @input = split("\t");
    my $title = shift(@input);

    for my $j (0..$#input) {
	$output[$j] = 0 unless exists $output[$j];
	$output[$j] += $input[$j];
    }
}
close(MATRIX);

for my $i (0..$#output) {
    print $i, "\t", $output[$i], "\n";
}

0;
