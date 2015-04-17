#!/usr/bin/perl
use strict;
use warnings;

# Takes as input matrix, output as sparse matrix

if ($#ARGV != -1) {
	print "usage: ./tosparse.pl < matrix > sparsematrix\n";
	exit;
};

# read header
my $header = <>;

while(<>) {
    chomp();
    my @fields = split("\t");
    my $title = shift @fields;
    my $i = $. - 1;
    for my $j (0 .. $#fields) {
	print $i, "\t", $i + $j, "\t", $fields[$j], "\n"
	    if ($fields[$j] != 0);
    }
}

0;
