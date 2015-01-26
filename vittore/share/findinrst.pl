#!/usr/bin/perl
use strict;
use warnings;

# Read in the restriction table

my %rsttable;
my $rstloaded = 0;
my %chrlength;
sub readrsttable {
    open RSTTABLE, "<", $_[0] or die $!;
    while (<RSTTABLE>) {
	chomp;
	my ($chrnum, $chrnam, $num, $st, $en) = split(" ", $_);

	$rsttable{$chrnam} = [] unless exists $rsttable{$chrnam};
	push $rsttable{$chrnam}, [ $st, $en ];
	$chrlength{$chrnam} = $en;
    }
    close RSTTABLE;
    $rstloaded = 1;
}

sub findinrst {
    die "Should call readrsttable first" if $rstloaded == 0;

    my $ele = $_[0]; my $chrnam = $_[1];
    print $ele, " " , $chrnam, "\n";
    die "Chromosome not found, ", $chrnam unless exists $chrlength{$chrnam};
    die "Read out of chromosome, ", $chrnam, " ", $ele 
	if $ele > $chrlength{$chrnam};

    my $aref = $rsttable{$chrnam};

    my $top = $#{$aref}; my $bottom = 0;
    while (1) {
        my $index = int(($top + $bottom)/2);

        if ($ele >= ${$aref}[$index][0] && $ele < ${$aref}[$index][1]) {
            print $index, " " , ${$aref}[$index][0], " ", ${$aref}[$index][1], "\n";
            return $index;
            last;
        } elsif ($ele < ${$aref}[$index][0]) {
            $top = $index - 1;
        } elsif ($ele >= ${$aref}[$index][1]) {
            $bottom = $index + 1;
        }
    }
}

1;
