#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw( shuffle );

# This the simulation framework (LOL)
#

if ($#ARGV != 4) {
	print "usage: ./simuly.pl classification intrap rsttable genomel simudata\n";
	exit;
};

my ($classificationfn, $intrap, $rsttablefn, $genomel, $simufn) = @ARGV;

# my $genomel = 4639675 (E. coli) or 4042928 (Cau. cresc. N1000)

open RSTTABLE, "<", $rsttablefn or die $!;
my @start; my @stop;
while (<RSTTABLE>) {
    chomp;
    my ($num, $st, $en) = split("\t", $_);
    push @start, $st;
    push @stop, $en;
}
close RSTTABLE;

sub findinrst {
    my $ele = $_[0];

    my $top = $#start; my $bottom = 0;
    while (1) {
        my $index = int(($top + $bottom)/2);

        if ($ele >= $start[$index] && $ele < $stop[$index]) {
            return $index;
            last;
        } elsif ($ele < $start[$index]) {
            $top = $index - 1;
        } elsif ($ele >= $stop[$index]) {
            $bottom = $index + 1;
        }
    }
}

use constant {
    FL_LEFT_NOTFOUND => 2,
    FL_RIGHT_NOTFOUND => 1,
    FL_LEFT_INVERSE => 8,
    FL_RIGHT_INVERSE => 4,
    FL_INVERSE => 16,
};

# Randomize distances

open(CLASSIFIC, "zcat $classificationfn |");

my @distances;
while (<CLASSIFIC>) {
    chomp;
    my ($num, $flag, $leftpos, $rightpos, $distance,
	$leftrst, $rightrst, $rstdist) = split("\t", $_);
    push @distances, $distance;
}

@distances = shuffle(@distances);
close CLASSIFIC;

# Make simulation output, note this is not coherent regarding to read
# directions, could be greatly improved, but at this point who cares.
open(SIMU, "| gzip > $simufn");                                                                                                                                                         
open(CLASSIFIC, "zcat $classificationfn |");

my $i = $#distances;
while (<CLASSIFIC>) {
    chomp;
    my ($num, $flag, $leftpos, $rightpos, $olddistance,
        $leftrst, $rightrst, $rstdist) = split("\t", $_);

    my $distance = $distances[$i]; $i--;
    if ($intrap < rand(1)) {
	if (int(rand(2))) {
	    $rightpos = $leftpos + $distance;
	} else {
	    $rightpos = $leftpos - $distance;
	}
    } else {
	if (int(rand(2))) {
            $rightpos = $genomel - $leftpos + $distance;
        } else {
            $rightpos = $genomel - $leftpos - $distance;
        }
    }

    $rightpos = $rightpos - $genomel if ($rightpos >= $genomel);
    $rightpos = $genomel + $rightpos if ($rightpos < 0);

    $flag &= ~FL_INVERSE;
    $rightrst = findinrst($rightpos);
    if ($leftpos >= $rightpos) {
        $distance = $leftpos - $rightpos;
        $rstdist = $leftrst - $rightrst;
        if ($distance > $genomel / 2) {
            $distance = $genomel - $distance;
            $rstdist = $#start - $rstdist;
        } else {
            $flag |= FL_INVERSE;
        }
    } else {
        $distance = $rightpos - $leftpos;
        $rstdist = $rightrst - $leftrst;
        if ($distance > $genomel / 2) {
            $distance = $genomel - $distance;
            $rstdist = $#start - $rstdist;
            $flag |= FL_INVERSE;
        }
    }

    printf SIMU "%d\t%.5b\t%d\t%d\t%d\t%d\t%d\t%d\n", $num, $flag, $leftpos, $rightpos, $distance, $leftrst, $rightrst, $rstdist;
}

die "Something weird is happening\n" if ($i != -1);

close CLASSIFIC;
close SIMU;

exit;
