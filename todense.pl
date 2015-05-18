#!/usr/bin/env perl
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
    die "Error found in matrixstripe.pl" if do "$Bin/matrixstripe.pl";
    die $@ if $@;
}

0;
