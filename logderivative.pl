#!/usr/bin/env perl
use strict;
use warnings;

# Takes as input matrix, output a vector

if ($#ARGV != 0) {
    print STDERR "usage: ./colmean.pl vector\n";
    exit -1;
}
my $vectorfn = shift @ARGV;

# open input files
if ($vectorfn eq '-') {
    *VECTOR = *STDIN;
} elsif ($vectorfn =~ /\.gz$/) {
    open(VECTOR, "gzip -d -c $vectorfn |");
} else {
    open(VECTOR, "< $vectorfn");
}

# load vector into memory
my @xax;
my @histogram;
my @variance;
while(<VECTOR>) {
    chomp;
    my ($x,$y,$z) = split("\t");
    push @xax, $x;
    push @histogram, $y;
    push @variance, $z;
}
close(VECTOR);

# guess steps and if it is logarithmic
my $m = 0; my $v = 0;
for my $i (4..$#xax) {
    $m += $xax[$i]/$xax[$i-1];
    $v += ($xax[$i]/$xax[$i-1])*($xax[$i]/$xax[$i-1]);
} $m /= $#xax-3; $v /= $#xax-3; $v -= $m*$m;
die "Binning does not looks like logarithmic ($m vs $v)" if
    sqrt($v) > 0.1 * $m;
my $steps = int($m * 100 + 0.5) / 100;

# get maximun nonzero value
my $maxind = $#xax;
for ( ; $maxind >= 0; $maxind--) {
    last if $histogram[$maxind];
}
$maxind++ if $maxind != 0;

# get last zero before maxind 
my $minind;
for (my $k = 0; $k < $maxind; $k++) {
    $minind = $k unless $histogram[$k];
}
$minind++;

# calculate log derivative
my @logderivative;
my @logdervariance;
my $old = $histogram[$minind];
my $oldvar = $variance[$minind];
for (my $k = $minind + 1; $k < $maxind; $k++) {
    $logderivative[$k] = (log($histogram[$k])-log($old)) 
	/ (log($steps**$k) - log($steps**($k-1)));
    # Crappy method that ignore non-linearities
    $logdervariance[$k] = 1.0 / ((log($steps**$k) - log($steps**($k-1)))**2) * (
	1.0/($histogram[$k]**2) * $variance[$k] +
	1.0/($old**2)) * $oldvar;
    $old = $histogram[$k]; $oldvar = $variance[$k];
}

for my $i (1..$#xax) {
    print join("\t", $xax[$i], $logderivative[$i] // 0, $logdervariance[$i] // 0), "\n";
}

0;
