#!/usr/bin/perl
use strict;
use warnings;

# Takes as input matrix, output as sparse matrix

if ($#ARGV != 1) {
	print "usage: ./tosparse.pl matrix sparsematrix\n";
	exit;
};
my ($matrixfn, $sparsematrix) = @ARGV;

# open input files
if ($matrixfn eq '-') {
    *MATRIX = *STDIN;
} elsif ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

# output
if ($sparsematrix eq '-') {
    *OUTPUT = *STDOUT;
} else {
    my $gzipit =  ($sparsematrix =~ /\.gz$/) ? "| gzip -c" : "";
    open(OUTPUT, "$gzipit > $sparsematrix");
}

while(<MATRIX>) {
    chomp();
    my @fields = split("\t");
    my $title = shift @fields;
    my $i = $. - 1;
    for my $j (0 .. $#fields) {
	print OUTPUT $i, "\t", $i + $j, "\t", $fields[$j], "\n"
	    if ($fields[$j] != 0);
    }
}
close(OUTPUT);
close(MATRIX);

0;
