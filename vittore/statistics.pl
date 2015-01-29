#!/usr/bin/perl
use strict;
use warnings;

require 'share/flagdefinitions.pl';

# Takes as input the contact list with flags; outputs statistics
#

if ($#ARGV != 0) {
	print "usage: ./statistics.pl classification\n";
	exit;
};
my ($classificationfn) = @ARGV;

# open input files
if ($classificationfn =~ /\.gz$/) {
    open(CLASS, "gzip -d -c $classificationfn |");
} else {
    open(CLASS, "< $classificationfn");
}

my $tot = 0; my $al = 0; my $sin = 0; my $un = 0; my $dan = 0;
while (<CLASS>) {
    my @campi = split("\t");
    my $flag = $campi[1];
    $tot++;
    $al++ if aligned($flag);
    $sin++ if single($flag);
    $un++ if bothunaligned($flag);
    $dan++ if dangling($flag);
}

print "$tot Total, ", "$sin Single, "
    , "$un Both unaligned, ", "$al Aligned, of which ", "$dan PlusMinus", "\n";

die "Something weird is happening, counts are not coherent, will die in shame\n"
    if ($tot - $sin - $un - $al);

0;
