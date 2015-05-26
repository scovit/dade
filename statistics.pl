#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/flagdefinitions.pl";
}

# Takes as input the contact list with flags; outputs statistics
#

if ($#ARGV != -1) {
	print STDERR "usage: ./statistics.pl < classification > stats\n";
	exit;
};

my $tot = 0; my $al = 0; my $sin = 0; my $un = 0; my $schr = 0;
my $dangling = 0;
while (<>) {
    my @campi = split("\t");
    my $flag = $campi[1];
    $tot++;
    $al++ if aligned($flag);
    $sin++ if single($flag);
    $un++ if bothunaligned($flag);
    $schr++ if (is(FL_INTRA_CHR, $flag) && aligned($flag));
    $dangling++ if plusmin($flag);
}

print sprintf("%d Total, ", $tot)
    , sprintf("%d (%.1f%%) Single, ", $sin, $sin/$tot*100)
    , sprintf("%d (%.1f%%) Both unaligned, ", $un, $un/$tot*100)
    , sprintf("%d (%.1f%%) Aligned\n", $al, $al/$tot*100)
    , sprintf("of which %d (%.1f%%) SameChromosome, ", $schr, $schr/$al*100)
    , sprintf("of which %d (%.1f%%) PlusMinus\n", $dangling,
	      $dangling/$schr*100);

die "Something weird is happening, counts are not coherent, will die in shame\n"
    if ($tot - $sin - $un - $al);

0;
