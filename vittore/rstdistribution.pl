#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    require 'share/flagdefinitions.pl';
}

# Takes as input the contact list with flags; outputs histograms of
# aligned reads
#

if ($#ARGV != 5) {
	print "usage: ./rstdistribution.pl classification nrst"
	    , " plusplus plusmin minplus minmin\n";
	exit;
};
my ($classificationfn, $nrst,
    $plusplusfn, $plusminfn, $minplusfn, $minminfn) = @ARGV;
die "Nrst should be a number" if (!looks_like_number($nrst));

# open input files
if ($classificationfn =~ /\.gz$/) {
    open(CLASS, "gzip -d -c $classificationfn |");
} else {
    open(CLASS, "< $classificationfn");
}

# create histograms
my @pp = (0) x $nrst;
my @pm = (0) x $nrst;
my @mp = (0) x $nrst;
my @mm = (0) x $nrst;

while (<CLASS>) {
    my @campi = split("\t");
    my $flag = $campi[1]; my $rstdst = $campi[9];
    if (aligned($flag) && is(FL_INTRA_CHR, $flag) && ($rstdst < $nrst)) {
	$pp[$rstdst]++ if plusplus($flag);
	$pm[$rstdst]++ if plusmin($flag);
	$mp[$rstdst]++ if minplus($flag);
	$mm[$rstdst]++ if minmin($flag);	
    }
}
close(CLASS);

# open output files
open(PP, "> $plusplusfn");
open(PM, "> $plusminfn");
open(MP, "> $minplusfn");
open(MM, "> $minminfn");

for (my $i = 0; $i < $nrst; $i++) {
    print PP $nrst, "\t", $pp[$i], "\n";
    print PM $nrst, "\t", $pm[$i], "\n";
    print MP $nrst, "\t", $mp[$i], "\n";
    print MM $nrst, "\t", $mm[$i], "\n";
} 

close(PP);
close(PM);
close(MP);
close(MM);
    
0;
