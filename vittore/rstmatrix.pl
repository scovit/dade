#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    require 'share/findinrst.pl';
    require 'share/flagdefinitions.pl';
}

# Takes as input the contact list with flags; outputs histograms of
# aligned reads in function of distance
#

if ($#ARGV != 2) {
	print "usage: ./rstmatrix.pl classification rsttable nrstfilter"
	    , "\n"
	    , "  output will be named after classification with additional\n"
	    , "  extensions .matrix\n";
	exit;
};
my ($classificationfn, $rsttablefn, $nrst) = @ARGV;

die "Nrstfilter should be a number" if (!looks_like_number($nrst));

my $TMPDIR="/data/temporary";

# open input files
if ($classificationfn =~ /\.gz$/) {
    open(CLASS, "gzip -d -c $classificationfn |");
} else {
    open(CLASS, "< $classificationfn");
}
readrsttable($rsttablefn);

my $alignedfn=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.couples");
open(ALIGN, "| sort -t \"\\t\" --parallel=8 -k 1,2 -g " 
     . "--temporary-directory=$TMPDIR > $alignedfn");

# Filter and sort
our %rsttable;
while (<CLASS>) {
    my @campi = split("\t");
    my (undef, $flag, $leftchr, undef, $leftrst, $rightchr,
	undef, $rightrst, undef, undef) = @campi;

    my $leftgrst = ${ $rsttable{$leftchr} }[$leftrst][0];
    my $rightgrst = ${ $rsttable{$leftchr} }[$rightrst][0];
    
    if (isaligned($flag)) {
	if ($leftgrst < $rightgrst) {
	    print ALIGN $leftgrst, "\t", $rightgrst, "\n";
	} else {
	    print ALIGN $rightgrst, "\t", $leftgrst, "\n";
	}
    }
}
close(CLASS);
close(ALIGN);

die;