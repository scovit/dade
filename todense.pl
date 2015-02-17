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
if ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

# output
my $gzipit =  ($densematrix =~ /\.gz$/) ? "| gzip -c" : "";
open(OUTPUT, "$gzipit > $densematrix");

while(<MATRIX>) {
    my $i = $. - 1;
    my @tmparray = (0) x $i;
    print OUTPUT join("\t", @tmparray), "\t", $_;
}
close(OUTPUT);
close(MATRIX);

0;
