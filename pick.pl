#!/bin/env perl

use strict;
use IPC::Open3;

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

my $pid = open3("<&STDIN", my $selectionIPC, ">&STDERR", "-");
unless ($pid) {
    while (<STDIN>) {
	my %in = parse_class;
	if ($compiled->(\%in)) {
	    print;
	}
    }
    exit(0);
}

open(my $left , "<", $leftmapfn);
open(my $right, "<", $rightmapfn);

while (<$selectionIPC>) {
    my %in = parse_class;

    # Find the sequences
    my $leftl; my $rigtl;
    while($leftl = <$left>) {
	$rigtl = <$right>;
	last if($. == $in{INDEX} * 4 + 2);
    }

    print join("\t", $in{INDEX}, $in{FLAG},
	       $in{LEFTCHR}, $in{LEFTPOS}, $in{LEFTRST}, $leftl);
    print join("\t", $in{INDEX}, $in{FLAG},
	       $in{RIGHTCHR}, $in{RIGHTPOS}, $in{RIGHTRST}, $rigtl);
}

waitpid( $pid, 0 );
close LEFT;
close RIGT;
