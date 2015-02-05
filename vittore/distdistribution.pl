#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);
use POSIX qw/floor/;
use List::Util qw(sum);

BEGIN {
    require 'share/flagdefinitions.pl';
}

# Takes as input the contact list with flags; outputs histograms of
# aligned reads in function of distance
#

if ($#ARGV != 3) {
	print "usage: ./rstdistribution.pl classification nrstfilter "
	    , "stepsize (log|lin)\n"
	    , "  output will be named after classification with additional\n"
	    , "  extension .CHR.EXT\n"
	    , "  where CHR is the name of chromosome as per alignment\n"
	    , "  and EXT can be either linhist or loghist\n";
	exit;
};
my ($classificationfn, $nrst,
    $steps, $type) = @ARGV;

die "Nrstfilter should be a number" if (!looks_like_number($nrst));
die "Stepsize should be a number" if (!looks_like_number($steps));
die "Stepsize is expected to be greater than 1" if ($steps <= 1);
die "(log|lin) should be either \"log\", or \"lin\""
    if (($type ne "log") && ($type ne "lin"));
my $islog = ($type eq "log" ? 1 : 0);

# open input files
if ($classificationfn =~ /\.gz$/) {
    open(CLASS, "gzip -d -c $classificationfn |");
} else {
    open(CLASS, "< $classificationfn");
}

# histograms
my $histosize = 10000;
my %histograms;
my @binscale = (0) x $histosize;
my @binsize = (0) x $histosize;
for (my $i = 0; $i < $histosize; $i++) {
    $binscale[$i] = ($islog
		      ? $steps ** ((2.0 * $i + 1.0) / 2)
		      : $steps *  ((2.0 * $i + 1.0) / 2));
    $binsize[$i] = ($islog
		    ? ($steps ** ($i + 1)) - ($steps ** $i)
		    : $steps );
}

while (<CLASS>) {
    my @campi = split("\t");
    my $flag = $campi[1]; my $chr = $campi[2];
    my $dist = $campi[8], my $rstdst = $campi[9];
    
    $histograms{$chr} = [(0) x $histosize] unless
	exists $histograms{$chr};

    next if (!aligned($flag)
	     || isnot(FL_INTRA_CHR, $flag)
	     || ($islog && $dist < 1.0)); 
    
    my $bin = ($islog
	       ? floor(log($dist) / log($steps))
	       : floor($dist / $steps));

    die "Histograms are defined too small: found bin = ", $bin, "\n"
	, 'while $histosize = ', $histosize, " , please increase me!\n"
	, '(or increase stepsize), BTW I\'m dieing now.\n'
        unless $bin < $histosize;

    # Global normalization (don't consider locus variability)
    if  ($rstdst > $nrst) {
	${ $histograms{$chr} }[$bin]++ if ($rstdst > $nrst);
    } elsif (minmin($flag) || plusplus($flag)) {
	${ $histograms{$chr} }[$bin] += 2;
    }
}
close(CLASS);

my $ext = ($islog ? "loghist" : "linhist");
# save output files
for my $chr ( keys %histograms ) {
    my $chrext = $chr;
    $chrext =~ s/ /_/g;
    $chrext =~ s/[^A-Za-z0-9_.]/~/g;

    # get maximun nonzero value
    my $maxind = $histosize;
    for (; $maxind >= 0; $maxind--) {
	last if ${ $histograms{$chr} }[$maxind];
    }
    $maxind++ if $maxind != 0;

    # normalize and make density
    my $summa = sum(@{ $histograms{$chr} });
    for (my $i = 0; $i < $maxind; $i++) {
	${ $histograms{$chr} }[$i] = (${ $histograms{$chr} }[$i]
				      / $summa / $binsize[$i]);
    }

    # calculate log derivative
    my @logderivative =  (0) x $histosize;
    if ($islog) {
	my $old = ${ $histograms{$chr} }[0];
	for (my $i = 1; $i < $maxind; $i++) {
	    if ($old == 0) {
		$old = ${ $histograms{$chr} }[$i];
		next;
	    }
	    $logderivative[$i] = (log(${ $histograms{$chr} }[$i] / $old) 
				  / log($binsize[$i - 1]));
	    $old = ${ $histograms{$chr} }[$i];
	}
    }
    
    # output the histogram
    open(HISTFILE, "> $classificationfn.$chrext.$ext");
    for (my $i = 0; $i < $maxind; $i++) {
	print HISTFILE $binscale[$i], "\t", ${ $histograms{$chr} }[$i];
	print HISTFILE "\t", $logderivative[$i] if $islog;
	print HISTFILE "\n";
    }
    close(HISTFILE);
}

0;
