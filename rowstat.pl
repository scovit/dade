#!/usr/bin/env perl
use strict;
use warnings;

# Takes as input matrix, output a vector
# Basically a oneliner, but since we have colsum ....

if ($#ARGV != -1) {
    print STDERR "usage: ./rowsum.pl < matrix\n";
    exit;
}

# output, stdout
my $header = <>;
print "\"ROWSTAT\"\n";
while(<>) {
    chomp;
    my @input = split("\t");
    my $title = shift(@input);
    $title =~ s/(^.|.$)//g;
    my (undef,undef,undef,$st,$en) = split("~", $title);
    my $len = $en - $st;

    my ($sum, $mean, $variance) = (0, 0, 0);
    for my $i (0..$#input) {
	$sum += $input[$i];
	$mean += $i * $input[$i];
	$variance += $i * $i * $input[$i];
    }
    unless ($sum == 0) {
	$mean = $mean / $sum; $variance = $variance / $sum;
	$variance -= $mean * $mean;
    }
    
    print join("\t", "\"$title\"", $len, $sum, $mean, $variance), "\n";
}

0;
