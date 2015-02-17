#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
}

# Takes as input the rstmatrix, rebin into genomic distance

if ($#ARGV != 3) {
	print "usage: ./rebin.pl matrix rsttable binsize(bp) binmatrix\n";
	exit;
};
my ($matrixfn, $rsttablefn, $binsize, $binmatrix) = @ARGV;

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
	print $#bins, "\n" if $index > 0;
	push @bins, [];
	$currchr = $chrnam;
	$binstart = 0;
	print $currchr, "\t", $#bins, "\t";
    }
    while ($binstart + $binsize < $rstpos) {
	push @bins, [];
	$binstart += $binsize;
    }

    push @{ $bins[$#bins] }, $index; 
}
print  $#bins, "\n";

# rebin
my $gzipit =  ($binmatrix =~ /\.gz$/) ? "| gzip -c" : "";
open(OUTPUT, "$gzipit > $binmatrix");
# Line index
$|++;
for my $binan (0 .. $#bins) {
    my @inputs;
    my @inputsln;
    my @output = (0) x scalar(@bins);

    print "\33[2K\rElaborating bin $binan out of $#bins";

    # Load a whole row bin into memory
    for my $i (0 .. $#{$bins[$binan]}) {
	my $line = <MATRIX>;
	my $ln = $. - 1;
	chomp($line);
	push @inputs, [ split("\t", $line) ];
	push @inputsln, $ln;
    }

    # column index
    for my $binbn ($binan .. $#bins) {
	for my $i (@{$bins[$binbn]}) {
	    for my $j (0 .. $#inputs) {
		$output[$binbn] += ${$inputs[$j]}[ $i - $inputsln[$j] ];
	    }
	}
    }
    
    print OUTPUT join("\t", @output), "\n";
}
close(OUTPUT);
close(MATRIX);

print "\33[2K\rEND\n";

0;
