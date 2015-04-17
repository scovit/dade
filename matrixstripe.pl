#!/usr/bin/env perl
use strict;
use warnings;

# Warning: this script, as it is, may use huges amount of RAM
# @l arrays may be tied to temporary files instead of packed strings

BEGIN {
    use FindBin '$Bin';
    use Tie::Array::Packed;
    require "$Bin/share/Metaheader.pm";
}

if ($#ARGV != 0) {
    print STDERR "usage: ./matrixstrip.pl block < input > output\n";
    exit -1;
}
my $blockstring = pop @ARGV;

# Read the header
my $header = <>;
chomp($header);
my $metah = Metaheader->new($header);
my @rowarray = @{ $metah->{rowinfo} };

print join("\t", "\"die\"", @{ $metah->{strings} }),"\n";

my @output = $metah->selectvector($blockstring);
die "No match" if ($#output == -1);

my @l = map {Tie::Array::Packed::IntegerNative->make()} @output;
#my @l = map {[]} @output;

my $j = 0;
while (<>) {
    last if ($#output == -1);

    chomp;
    my @r=split("\t");
    my $head=shift @r;

    if ($j == $output[0]) {

	print join("\t", $head, @{$l[0]}, @r),"\n";

	shift @output;
	shift @l;
    }

    for my $i (0..$#output) {
	push @{$l[$i]}, $r[$output[$i]-$j];
    }

    $j++;
}

0;
