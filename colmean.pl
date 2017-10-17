#!/usr/bin/env perl
use strict;
use warnings;

# Takes as input matrix, output a vector

if ($#ARGV != -1) {
    print STDERR "usage: ./colmean.pl < matrix > output\n";
    exit -1;
}

# output, stdout
my @mean;
my @var;
my @stddev;
my @n;
my $header = <STDIN>;
chomp($header);
my @outputtit = split("\t", $header);
shift @outputtit;

while(<STDIN>) {
    chomp;
    my @input = split("\t");
    my $title = shift(@input);

    for my $j (0..$#input) {
	$mean[$j] = ($mean[$j] // 0) + $input[$j];
	$var[$j] = ($var[$j] // 0) + $input[$j]*$input[$j];
	$n[$j] = ($n[$j] // 0) + 1;
    }
}

for my $j (0..$#n) {
    $mean[$j] /= $n[$j];
    $var[$j] /= $n[$j]; $var[$j] -= $mean[$j]*$mean[$j];
}

for my $j (0..$#n) {
    print join("\t", $outputtit[$j]
	           , $mean[$j]
                   , sqrt($var[$j])
                   , $n[$j]), "\n";
}

0;
