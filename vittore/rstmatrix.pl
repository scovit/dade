#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
    require "$Bin/share/flagdefinitions.pl";
    require "$Bin/share/mktemp_linux.pl";
}

# Takes as input the contact list with flags; outputs interaction matrices
#

if ($#ARGV != 2) {
	print "usage: ./rstmatrix.pl classification rsttable nrstfilter"
	    , "\n"
	    , "  output will be named after classification with additional\n"
	    , "  extensions .matrix.gz and .sparse.gz\n"
	    , "  (open with \"gzip -d -c\")\n";
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
open(ALIGN, "| sort --parallel=8 --temporary-directory=$TMPDIR " .
     "-g -k 1 -k 2 > $alignedfn");

# Filter and sort
our %rsttable;
while (<CLASS>) {
    my @campi = split("\t");
    my (undef, $flag, $leftchr, undef, $leftrst, $rightchr,
	undef, $rightrst, undef, undef) = @campi;

    if (aligned($flag)) {
	my $leftgrst = ${ $rsttable{$leftchr} }[$leftrst][0];
	my $rightgrst = ${ $rsttable{$rightchr} }[$rightrst][0];
	if ($leftgrst < $rightgrst) {
	    print ALIGN $leftgrst, "\t", $rightgrst, "\t", $flag, "\n";
	} else {
	    print ALIGN $rightgrst, "\t", $leftgrst, "\t", $flag, "\n";
	}
    }
}
close(CLASS);
close(ALIGN);

link($alignedfn, $alignedfn . ".dbg");

open(ALIGN, "< $alignedfn");
open(OUTPUT, "| gzip -c > $classificationfn.matrix.gz");
open(SPARSE, "| gzip -c > $classificationfn.sparse.gz");

our @rstarray;
my @intervector = (0) x scalar(@rstarray);
my $oldleftgrst = 0; my $oldrightgrst = 0;
while (<ALIGN>) {
    my @campi = split("\t");
    my ($leftgrst, $rightgrst, $flag) = @campi;

    die "Wierd things happening"
	if (($leftgrst < $oldleftgrst) || ($rightgrst < $oldrightgrst));

    if (($leftgrst != $oldleftgrst) || ($rightgrst != $oldrightgrst)) {
	if ($intervector[$oldrightgrst] != 0) {
	    print SPARSE $oldleftgrst, "\t", $oldrightgrst, "\t"
		, $intervector[$oldrightgrst], "\n";
	}
    }

    if ($leftgrst != $oldleftgrst) {
	print OUTPUT join("\t", @intervector), "\n";
	for my $i (0 .. $#intervector) { $intervector[$i] = 0; };
	for ( $oldleftgrst++; $oldleftgrst < $leftgrst; $oldleftgrst++) {
	    print OUTPUT join("\t", @intervector), "\n";
	}
    }

    if (($rightgrst - $leftgrst < $nrst)
	&& is(FL_INTRA_CHR, $flag)) {
	$intervector[$rightgrst] += 2 if (plusplus($flag) || minmin($flag));
    } else {
	$intervector[$rightgrst]++;
    }
    $oldleftgrst = $leftgrst; $oldrightgrst = $rightgrst;
}

if ($intervector[$oldrightgrst] != 0) {
    print SPARSE $oldleftgrst, "\t", $oldrightgrst, "\t"
	, $intervector[$oldrightgrst], "\n";
}
print OUTPUT join("\t", @intervector), "\n";
for my $i (0 .. $#intervector) { $intervector[$i] = 0; };
for ( $oldleftgrst++; $oldleftgrst <= $#intervector; $oldleftgrst++) {
    print OUTPUT join("\t", @intervector), "\n";
}

close(ALIGN);
close(SPARSE);
close(OUTPUT);

0;
