#!/usr/bin/env perl
use strict;
use warnings;

# Takes as input matrix, output a vector

if ($#ARGV != -1) {
    print STDERR "usage: ./logderivative.pl < vector > deriv\n";
    exit -1;
}

# load vector into memory
my @xax;
my @histogram;
my @variance;
my $novariance = 0;
while(<>) {
    chomp;
    my ($x,$y,$z) = split("\t");
    $novariance++ unless defined($z);
    push @xax, $x;
    push @histogram, $y;
    push @variance, $z;
}

# guess steps and if it is logarithmic
my $m = 0; my $v = 0;
for my $i (4..$#xax) {
    $m += $xax[$i]/$xax[$i-1];
    $v += ($xax[$i]/$xax[$i-1])*($xax[$i]/$xax[$i-1]);
} $m /= $#xax-3; $v /= $#xax-3; $v -= $m*$m;
die "Binning does not looks like logarithmic ($m vs $v)" if
    sqrt($v) > 0.1 * $m;
my $steps = int($m * 100 + 0.5) / 100;

# guess start point


# get maximun nonzero value
my $maxind = $#xax;
for ( ; $maxind >= 0; $maxind--) {
    last if $histogram[$maxind];
}
$maxind++ if $maxind != 0;

# get last zero before maxind 
my $minind = -1;
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
	/ log($steps);
    # Crappy method that ignore non-linearities
    unless ($novariance) {
	$logdervariance[$k] = 1.0 /
	    ((log($steps**$k) - log($steps**($k-1)))**2) * (
		1.0/($histogram[$k]**2) * $variance[$k] +
		1.0/($old**2)) * $oldvar;
    }
    $old = $histogram[$k]; $oldvar = $variance[$k];
}

for my $i (1..$#xax) {
    print join("\t", $xax[$i], $logderivative[$i] // 0, $logdervariance[$i] // 0), "\n";
}

0;
