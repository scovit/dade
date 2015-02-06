#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
    require "$Bin/share/flagdefinitions.pl";
}

# Takes as input the contact list with flags; outputs histograms of
# aligned reads in function of distance
#

if ($#ARGV != 2) {
	print "usage: ./rstmatrix.pl classification rsttable nrstfilter"
	    , "\n"
	    , "  output will be named after classification with additional\n"
	    , "  extensions .matrix.gz , open with \"gzip -d -c\"\n";
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

link($alignedfn, $alignedfn . ".dbg");

open(ALIGN, "< $alignedfn");
open(OUTPUT, "| gzip -c > $classificationfn.matrix.gz");

our @rstarray;
my @intervector = (0) x scalar(@rstarray);
my $oldleftgrst = 0; my $oldrightgrst = 0;
while (<ALIGN>) {
    my @campi = split("\t");
    my ($leftgrst, $rightgrst) = @campi;

    die "Wierd things happening"
	if (($leftgrst < $oldleftgrst) || ($rightgrst < $oldrightgrst));

    if ($leftgrst != $oldleftgrst) {
	print OUTPUT join("\t", @intervector), "\n";
	for (@intervector) { $_ = 0; };
	for ( $oldleftgrst++; $oldleftgrst < $leftgrst; $oldleftgrst++) {
	    print OUTPUT join("\t", @intervector), "\n";
	}
    }

    $intervector[$rightgrst]++;
    $oldleftgrst = $leftgrst; $oldrightgrst = $rightgrst;
}
close(ALIGN);
close(OUTPUT);

0;
