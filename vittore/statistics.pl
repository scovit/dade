#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    require 'share/flagdefinitions.pl';
}

# Takes as input the contact list with flags; outputs statistics
#

if ($#ARGV != 0) {
	print "usage: ./statistics.pl classification\n";
	exit;
};
my ($classificationfn) = @ARGV;

# open input files
if ($classificationfn =~ /\.gz$/) {
    open(CLASS, "gzip -d -c $classificationfn |");
} else {
    open(CLASS, "< $classificationfn");
}

my $tot = 0; my $al = 0; my $sin = 0; my $un = 0; my $schr = 0;
my $dangling = 0;
while (<CLASS>) {
    my @campi = split("\t");
    my $flag = $campi[1];
    $tot++;
    $al++ if aligned($flag);
    $sin++ if single($flag);
    $un++ if bothunaligned($flag);
    $schr++ if is(FL_INTRA_CHR, $flag);
    $danhling++ if plusmin($flag);
}
close(CLASS);

print "$tot Total, ", "$sin Single, "
    , "$un Both unaligned, ", "$al Aligned\n"
    , "of which $schr SameChromosome, of which ", "$dangling PlusMinus", "\n";

die "Something weird is happening, counts are not coherent, will die in shame\n"
    if ($tot - $sin - $un - $al);

0;
