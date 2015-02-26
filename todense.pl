#!/usr/bin/perl
use strict;
use warnings;

# Takes as input matrix, output as dense matrix

if ($#ARGV != 1) {
	print "usage: ./todense.pl matrix densematrix\n";
	exit;
};
my ($matrixfn, $densematrix) = @ARGV;

# open input files
if ($matrixfn eq '-') {
    *MATRIX = *STDIN;
} elsif ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

# output
if ($densematrix eq '-') {
    *OUTPUT = *STDOUT;
} else {
    my $gzipit =  ($densematrix =~ /\.gz$/) ? "| gzip -c" : "";
    open(OUTPUT, "$gzipit > $densematrix");
}

# read header
my $header = <MATRIX>;

while(<MATRIX>) {
    my $i = $. - 1;
    my @tmparray = (0) x $i;
    chomp;
    my @input = split("\t");
    my $title = shift(@input);

    print OUTPUT join("\t", (@tmparray, @input)), "\n";
}
close(OUTPUT);
close(MATRIX);

0;
