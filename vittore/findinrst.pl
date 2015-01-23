#!/usr/bin/perl
use strict;
use warnings;

# Read in the restriction table

my %rsttable;
my $rstloaded = 0;
sub readrsttable {
    open RSTTABLE, "<", $_[0] or die $!;
    while (<RSTTABLE>) {
	chomp;
	my ($chrnum, $chrnam, $num, $st, $en) = split(" ", $_);

	$rsttable{$chrnam} = [] unless exists $rsttable{$chrnam};
	push $rsttable{$chrnam}, [ $st, $en ];
    }
    close RSTTABLE;
    $rstloaded = 1;
}

sub findinrst {
    die "Should call readrsttable first" if $rstloaded == 0;

    my $ele = $_[0]; my $chrnam = $_[1];

    my $aref = $rsttable{$chrnam};

    my $top = $#{$aref}; my $bottom = 0;
    while (1) {
        my $index = int(($top + $bottom)/2);

        if ($ele >= ${$aref}[$index][0] && $ele < ${$aref}[$index][1]) {
            return ($index, ${$aref}[$index][0], ${$aref}[$index][1]);
            last;
        } elsif ($ele < ${$aref}[$index][0]) {
            $top = $index - 1;
        } elsif ($ele >= ${$aref}[$index][1]) {
            $bottom = $index + 1;
        }
    }
}

1;
