#!/usr/bin/env perl
use strict;
use warnings;

# Takes as input matrix, output a vector

my $isalg = 0;
if ($#ARGV > 1 || ($#ARGV != 0 && ($ARGV[0] // '') ne "-a")) {
    print STDERR "usage: ./colsum.pl [-a] matrix\n\n"
	,"   -a algebric column index (vs upper diagonal format)\n";
    exit;
} elsif ($#ARGV == 1) {
    $isalg = 1;
    shift @ARGV;
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
my @output;
my $header = <MATRIX>;
chomp($header);
my @outputtit = split("\t", $header);
shift @outputtit;

my $i = 0;
while(<MATRIX>) {
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
close(MATRIX);

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
