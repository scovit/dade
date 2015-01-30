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
    $dangling++ if plusmin($flag);
}
close(CLASS);

print sprintf("%d Total, ", $tot)
    , sprintf("%d (%.1f%) Single, ", $sin, $sin/$tot*100)
    , sprintf("%d (%.1f%) Both unaligned, ", $un, $un/$tot*100)
    , sprintf("%d (%.1f%) Aligned\n", $al, $al/$tot*100)
    , sprintf("of which %d (%.1f%) SameChromosome, ", $schr, $schr/$al*100)
    , sprintf("of which %d (%.1f%) PlusMinus\n", $dangling,
	      $dangling/$schr*100);

die "Something weird is happening, counts are not coherent, will die in shame\n"
    if ($tot - $sin - $un - $al);

0;
