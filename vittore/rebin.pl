#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
}

# Takes as input the rstmatrix, rebin into genomic distance

if ($#ARGV != 2) {
	print "usage: ./rebin.pl matrix rsttable binsize(bp)"
	    , "\n"
	    , "  output will be named after matrix with additional\n"
	    , "  extensions .rebinned\n";
	exit;
};
my ($matrixfn, $rsttablefn, $binsize) = @ARGV;

die "Binsize should be a number" if (!looks_like_number($binsize));

# open input files
if ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}
readrsttable($rsttablefn);

# Make the bin table
our @rstarray;
my @bins;
my $binstart = 0;
my $currchr = "";
# my $rst = [ $index, $chrnam, $num, $st, $en ];
for my $rst (@rstarray) {
    my ($index, $chrnam, $num, $st, $en ) = @$rst;
    my $rstpos = ($st + $en)/2;
    
    # new bin?
    if ($chrnam ne $currchr) {
	print $index - 1, "\n" if $index > 0;
	push @bins, [];
	$currchr = $chrnam;
	$binstart = 0;
	print $currchr, "\t", $index;
    }
    while ($binstart + $binsize < $rstpos) {
	push @bins, [];
	$binstart += $binsize;
    }

    push @{ $bins[$#bins] }, $index; 
}
print scalar(@rstarray), "\n";

# rebin
open(OUTPUT, "> $matrixfn.rebinned");
# Line index
for my $binan (0 .. $#bins) {
    my @inputs;
    my @output = (0) x scalar(@bins);

    print "Elaborating bin $binan out of $#bins\r" unless ($binan % 100);
    
    for my $i (0 .. $#${$bins[$binan]}) {
	my $line = <MATRIX>;
	chomp($line);
	push @inputs, [ split("\t", $line) ];
    }

    # column index
    for my $binbn (0 .. $#bins) {
	for my $i (@{$bins[$binbn]}) {
	    for my $j (@inputs) {
		$output[$binbn] += ${$j}[$i];
	    }
	}
    }
    
    print OUTPUT join("\t", @output), "\n";
}
close(OUTPUT);
close(MATRIX);

0;
