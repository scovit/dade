#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
}

# Takes as input matrix, output as dense matrix

if ($#ARGV != -1) {
	print "usage: ./todense.pl < matrix > densematrix\n";
	exit;
};

{
    local @ARGV = ("'1'");
    do "$Bin/matrixstripe.pl";
}

0;
