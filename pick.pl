#!/bin/env perl

use strict;

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/flagdefinitions.pl";
}

if (@ARGV != 3) {
        print STDERR "usage: ./zpick.pl block leftmap rightmap "
                      . "< classification\n";
        exit;
};
my $blockstring = shift(@ARGV);
my ($leftmapfn, $rightmapfn) = @ARGV;

my $compiled = eval
    'sub { local %_ = %{ shift @_; }; '. $blockstring .' }';
die $@ unless($compiled);

open(my $left , "<", $leftmapfn);
open(my $right, "<", $rightmapfn);

my $leftl; my $rigtl; my $ln;
while (<STDIN>) {
    my %in = parse_class;

    if ($compiled->(\%in)) {
	# Find the sequences
	while(($ln != $in{INDEX} * 4 + 2) && defined($leftl = <$left>)) {
	    $rigtl = <$right>;
	    $ln = $.;
	}

	print join("\t", $in{INDEX}, $in{FLAG},
		   $in{LEFTCHR}, $in{LEFTPOS}, $in{LEFTRST}, $leftl);
	print join("\t", $in{INDEX}, $in{FLAG},
		   $in{RIGHTCHR}, $in{RIGHTPOS}, $in{RIGHTRST}, $rigtl);
    }
}

close LEFT;
close RIGT;
