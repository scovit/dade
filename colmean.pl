#!/usr/bin/env perl
use strict;
use warnings;

# Takes as input matrix, output a vector

if ($#ARGV != 0) {
    print STDERR "usage: ./colmean.pl matrix\n";
    exit -1;
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
my @mean;
my @var;
my @stddev;
my @n;
my $header = <MATRIX>;
chomp($header);
my @outputtit = split("\t", $header);
shift @outputtit;

while(<MATRIX>) {
    chomp;
    my @input = split("\t");
    my $title = shift(@input);

    for my $j (0..$#input) {
	$mean[$j] = ($mean[$j] // 0) + $input[$j];
	$var[$j] = ($var[$j] // 0) + $input[$j]*$input[$j];
	$n[$j] = ($n[$j] // 0) + 1;
    }
}
close(MATRIX);

for my $j (0..$#n) {
    $mean[$j] /= $n[$j];
    $var[$j] /= $n[$j]; $var[$j] -= $mean[$j]*$mean[$j];
}

for my $j (0..$#n) {
    print $outputtit[$j], "\t", $mean[$j], "\t", sqrt($var[$j]/$n[$j]), "\n";
}

0;
