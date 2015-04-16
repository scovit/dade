#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/Metaheader.pm";
}

if ($#ARGV != 1) {
    print STDERR "usage: ./matrixstrip.pl block1 block2 < input > output\n";
    exit -1;
}
my $blockstring1 = shift @ARGV;
my $blockstring2 = shift @ARGV;

# Read the header
my $header = <>;
chomp($header);
my $metah = Metaheader->new($header);
my @rowarray = @{ $metah->{rowinfo} };

my @output1 = $metah->selectvector($blockstring1);
my @output2 = $metah->selectvector($blockstring2);
die "No match for block 1" if ($#output1 == -1);
die "No match for block 2" if ($#output2 == -1);

# check who is first
my $unofirst = $output1[0] > $output2[0] ? 1 : 0;
# check for overlap
die "Blocks are overlapping" if 
    ( $unofirst ?
      $output2[0] < $output1[$#output1] :
      $output1[0] < $output2[$#output2] );

if ($unofirst) {
    # print header
    print join("\t", "\"die\"",
	       $metah->{strings}->[@output2]), "\n";

    my $j = 0;
    while (<>) {
	last if ($#output1 == -1);

	if ($j == $output1[0]) {

	    chomp;
	    my @r=split("\t");
	    my $head=shift @r;

	    my @rsel = map { $_ - $j } @output2;
	    print join("\t", $head, @r[@rsel]),"\n";

	    shift @output1;
	}

	$j++;
    }

} else { 
    # not $unofirst
    # print header
    print join("\t", "\"die\"",
	       $metah->{strings}->[@output2]), "\n";

    # Warning: this script, as it is, may use huges amount of RAM
    # @l arrays may be tied to temporary files

    my @l = map {[]} @output1;

    my $j = 0;
    while (<>) {
	last if ($#output2 == -1);

	if ($j == $output2[0]) {

	    chomp;
	    my @r=split("\t");
	    my $head=shift @r;

	    my @rsel = map { $_ - $j } @output1;

	    for my $i (0..$#output1) {
		push @{$l[$i]}, $r[$output1[$i]-$j];
	    }

	    shift @output2;
	}

	$j++;
    }

    for my $i (0..$#output1) {
	print join("\t", $metah->{strings}->[$output1[$i]],
		   @{ $l[$i] }),"\n";
    }

}
