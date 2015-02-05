#!/usr/bin/perl
use strict;
use warnings;

# Read in the restriction table

our %rsttable;
our @rstarray;
my $rstloaded = 0;
our %chrlength;
sub readrsttable {
    my $fname = $_[0];
    open RSTTABLE, "<", $fname or die $!;
    while (<RSTTABLE>) {
	chomp;
	my ($index, $chrnam, $num, $st, $en) = split("\t", $_);

	$rsttable{$chrnam} = [] unless exists $rsttable{$chrnam};

	die "File format error in $fname" if ($index != $rstarray);

	my $rstinfo = [ $index, $chrnam, $num, $st, $en ];
	push @{ $rsttable{$chrnam} }, $rstinfo;
	push @rstarray, $rstinfo;
	$chrlength{$chrnam} = $en;
    }
    close RSTTABLE;
    $rstloaded = 1;
} 

sub findinrst {
    die "Should call readrsttable first" if $rstloaded == 0;

    my $ele = $_[0]; my $chrnam = $_[1];
    if ($chrnam eq "*") {
	return "*";
    }
    die "Chromosome not found, ", $chrnam unless exists $chrlength{$chrnam};
    die "Read out of chromosome, ", $chrnam, " ", $ele 
	if $ele > $chrlength{$chrnam};

    my $aref = $rsttable{$chrnam};

    my $top = $#{$aref}; my $bottom = 0;
    while (1) {
        my $index = int(($top + $bottom)/2);

        if ($ele >= ${$aref}[$index][0] && $ele < ${$aref}[$index][1]) {
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
