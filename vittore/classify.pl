#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    require 'share/flagdefinitions.pl';
}

# Takes as input the mapped reads and output the contact list with flags
#

if ($#ARGV != 2) {
	print "usage: ./classify.pl leftmap rightmap classification\n";
	exit;
};

my ($leftmapfn, $rightmapfn, $classificationfn) = @ARGV;

my $minqual = 30;

# open input files
if ($leftmapfn =~ /\.gz$/) {
    open(LEFTMAP, "gzip -d -c $leftmapfn |");
} else {
    open(LEFTMAP, "< $leftmapfn");
}
if ($rightmapfn =~ /\.gz$/) {
    open(RIGHTMAP, "gzip -d -c $rightmapfn |");
} else {
    open(RIGHTMAP, "< $rightmapfn");
}
# open output file
if  ($classificationfn =~ /\.gz$/) {
    open(CLASSIFIC, "| gzip > $classificationfn");
} else {
    open(CLASSIFIC, "> $classificationfn");
}

print "Starting classification\n";

for (my $num = 0; ; $num++) {

    my $ls = <LEFTMAP>; chomp($ls);
    my ($leftnum, $leftnam, $leftflag, $leftchr, $leftpos, $leftqual, $leftasize, $leftrst) = split("\t", $ls);
    my $rs = <RIGHTMAP>; chomp($rs);
    my ($rightnum, $rightnam, $rightflag, $rightchr, $rightpos, $rightqual, $rightasize, $rightrst) = split("\t", $rs);

    die "Input file format error\n" if (($leftnum != $num) || ($rightnum != $num));

    my $flag = 0;
    $flag |= FL_LEFT_INVERSE if ($leftflag & 16);
    $flag |= FL_RIGHT_INVERSE if ($rightflag & 16);
    $flag |= FL_LEFT_ALIGN if ((!($leftflag & 4)) && ($leftqual >= 30));
    $flag |= FL_RIGHT_ALIGN if ((!($rightflag & 4)) && ($rightqual >= 30));
    $flag |= FL_INTRA_CHR if (($leftchr eq $rightchr) && ($leftchr ne "*") && ($leftchr ne "*"));

    my $distance; my $rstdist;
    if ($flag & FL_INTRA_CHR) {
	if ($leftpos >= $rightpos) {
	    $distance = $leftpos - $rightpos;
	    $rstdist = $leftrst - $rightrst;
	    $flag |= FL_INVERSE;
	} else {
	    $distance = $rightpos - $leftpos;
	    $rstdist = $rightrst - $leftrst;
	}
    } else {
	$distance = "*";
	$rstdist = "*";
    }
    print CLASSIFIC $num, "\t", $flag, "\t"
	, $leftchr, "\t", $leftpos, "\t", $leftrst, "\t"
	, $rightchr, "\t", $rightpos, "\t", $rightrst, "\t"
	, $distance, "\t", $rstdist, "\n";

    last if (eof(LEFTMAP) && eof(RIGHTMAP));
}

close CLASSIFIC;
close LEFTMAP;
close RIGHTMAP;

exit;
