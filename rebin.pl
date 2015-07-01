#!/usr/bin/env perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);
use POSIX qw/floor/;
use List::MoreUtils qw(any);

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/Metaheader.pm";
}

# Takes as input the rstmatrix, rebin into genomic distance

if ($#ARGV != 0) {
	print STDERR "usage: ./rebin.pl binsize(bp) < matrix > binmatrix\n";
	exit;
};
my $binsize = shift @ARGV;

die "Binsize should be a number" if (!looks_like_number($binsize));

# Read the header
my $header = <>;
chomp($header);
my $metah = Metaheader->new($header);
my @rsts = @{ $metah->{rowinfo} };
warn "Metaheader lacks chromosome information... will rebin a single one"
    unless exists $rsts[0]->{chr};
die "Metaheader lacks position information... Sad, I cannot rebin"
    unless (exists $rsts[0]->{pos} ||
	    (exists $rsts[0]->{st} &&
	     exists $rsts[0]->{en}));

# Make the bin table
my @bins;
my @bintitle;
{
    my $binstartp;
    my $currchr = "-1";
    for my $i (0..$#rsts) {
	my $rstpos = $rsts[$i]->{pos} //
	    floor(($rsts[$i]->{st} + $rsts[$i]->{en}))/2;

	my $chrnam = $rsts[$i]->{chr} // "";

	# chromosome frontier?
	if ($chrnam ne $currchr) {
	    push @bins, [];
	    $binstartp = floor($rstpos / $binsize) * $binsize;
	    my $binpos = $binstartp + floor($binsize/2);
	    push @bintitle, "\"$chrnam~$binpos\"";
	    $currchr = $chrnam;
	}
	# empty bins if no rst is there
	while ($binstartp + $binsize < $rstpos) {
	    push @bins, [];
	    $binstartp += $binsize;
	    my $binpos = $binstartp + floor($binsize / 2);
	    push @bintitle, "\"$chrnam~$binpos\"";
	}

	push @{ $bins[$#bins] }, $i;
    }
}

# Print the header
print join("\t", "\"BIN\"", @bintitle), "\n";

# Cycle over bins (output rows)
for my $binan (0 .. $#bins) {
    my @inputs;
    my @output = (0) x ($#bins - $binan + 1);

    print STDERR "\33[2K\rElaborating bin $binan out of $#bins";

    # Load the whole rows of bin into memory (note, the script eats an
    # amount of memory proportional to the bin size)
    for my $i (0 .. $#{$bins[$binan]}) {
	my $line = <>;
	defined $line or die "Input format error";
	chomp $line;

	my @input = split("\t", $line); shift(@input);
	push @inputs, \@input;
    }

    # Cycle over bins (column index)
    for my $binbn ($binan .. $#bins) {

	for my $i (0 .. $#{$bins[$binan]}) {
	    for my $j (0 .. $#{$bins[$binbn]}) {
		next if (($binbn == $binan) && ($j < $i));
		my $coln = $bins[$binbn]->[$j] - $bins[$binan]->[$i];

		$output[$binbn - $binan] += $inputs[$i]->[$coln] //
		    die "Missing columns in input";
	    }
	}

    }
    
    print join("\t", $bintitle[$binan], @output), "\n";
}

print STDERR "\33[2K\rEND\n";

0;
