#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

# Takes as input matrix, output a vector

my $isalg = 0;
GetOptions("alg" => \$isalg)    # flag
  or die("Error in command line arguments\n");


if ($#ARGV != -1) {
    print STDERR "usage: ./colsum.pl [--alg] < matrix > sums\n";
    exit -1;
}

# output, stdout
my @output;
my $header = <>;
chomp($header);
my @outputtit = split("\t", $header);
shift @outputtit;

my $i = 0;
while(<>) {
    chomp;
    my @input = split("\t");
    my $title = shift(@input);
    if ($isalg) {
	my @tmparray = (0) x $i;
	@input = (@tmparray, @input);
    }

    for my $j (0..$#input) {
	$output[$j] = 0 unless exists $output[$j];
	$output[$j] += $input[$j];
    }
    $i++;
}

if ($isalg) {
    die "Weird matrix format" unless ($#outputtit == $#output);
    for my $j (0..$#output) {
	print $outputtit[$j], "\t", $output[$j], "\n";
    }    
} else {
    for my $j (0..$#output) {
	print $j, "\t", $output[$j], "\n";
    }
}

0;
