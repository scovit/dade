#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use Getopt::Long;
    require "$Bin/share/flagdefinitions.pl";
}

# Takes as input the mapped reads and output the contact list with flags
#

my $minqual = 30;
my $noambig = 0;
GetOptions("minq=i" => \$minqual, 'noambig' => \$noambig)    # integer arg
  or die("Error in command line arguments\n");

if ($#ARGV != 1) {
	print STDERR "usage: ./classify.pl [--minq=30] [--noambig] leftmap rightmap "
	              . "> classification\n";
	exit;
};

my ($leftmapfn, $rightmapfn) = @ARGV;

# open input files
open(LEFTMAP, "< $leftmapfn");
open(RIGHTMAP, "< $rightmapfn");

print STDERR "Starting classification\n";

my $aligne = ($noambig
	      ? sub {
		  my ($flag, $qual) = @_;
		  return ((!($flag & 4))
			  && (!($flag & 4096))
			  && ($qual >= $minqual)); }
	      : sub {
                  my ($flag, $qual) = @_;
                  return ((!($flag & 4))
                          && ($qual >= $minqual)); }
    );

for (my $num = 0; ; $num++) {

    my $ls = <LEFTMAP>; chomp($ls);
    my ($leftnum, $leftnam, $leftflag, $leftchr, $leftpos, $leftqual, $leftasize, $leftrst) = split("\t", $ls);
    my $rs = <RIGHTMAP>; chomp($rs);
    my ($rightnum, $rightnam, $rightflag, $rightchr, $rightpos, $rightqual, $rightasize, $rightrst) = split("\t", $rs);

    die "Input file format error\n" if (($leftnum != $num) || ($rightnum != $num));

    my $flag = 0;
    $flag |= FL_LEFT_INVERSE if ($leftflag & 16);
    $flag |= FL_RIGHT_INVERSE if ($rightflag & 16);
    $flag |= FL_LEFT_ALIGN if &$aligne($leftflag, $leftqual);
    $flag |= FL_RIGHT_ALIGN if &$aligne($rightflag, $rightqual);
    $flag |= FL_INTRA_CHR if (($leftchr eq $rightchr) && ($leftchr ne "*"));

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
    print $num, "\t", $flag, "\t"
	, $leftchr, "\t", $leftpos, "\t", $leftrst, "\t"
	, $rightchr, "\t", $rightpos, "\t", $rightrst, "\t"
	, $distance, "\t", $rstdist, "\n";

    last if (eof(LEFTMAP) && eof(RIGHTMAP));
}

close LEFTMAP;
close RIGHTMAP;

exit;
