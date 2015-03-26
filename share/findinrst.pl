#!/usr/bin/perl
use strict;
use warnings;

# Read in the restriction table

our %rsttable;
our @rstarray;
my $rstloaded = 0;
our %chrlength;
our @chrnames;
sub readrsttable {
    my $fname = $_[0];
    open RSTTABLE, "<", $fname or die $!;
    while (<RSTTABLE>) {
	chomp;
	my ($index, $chrnam, $num, $st, $en) = split("\t", $_);

	unless (exists $rsttable{$chrnam}) {
	    $rsttable{$chrnam} = [];
	    push @chrnames, $chrnam;
	    die "Index errors" if (($st != 0) || ($num != 0)); 
	}

	die "File format error in $fname" if ($index != scalar(@rstarray));
	die "Wierd rsttable" 
	    if ($st >= $en); 
	
	my $rstinfo = [ $index, $chrnam, $num, $st, $en ];
	push @{ $rsttable{$chrnam} }, $rstinfo;
	push @rstarray, $rstinfo;
	$chrlength{$chrnam} = $en;
    }
    close RSTTABLE;
    $rstloaded = 1;
}

sub readrsttable_from_header {
    my $header = $_[0];
    my @rsttable = split("\t", $header);
    shift @rsttable;
    for (@rsttable) {
	s/(^.|.$)//g;
	my ($index, $chrnam, $num, $st, $en) = split("~");

	unless (exists $rsttable{$chrnam}) {
	    $rsttable{$chrnam} = [];
	    push @chrnames, $chrnam;
	    die "Index errors, loaded records: $#rstarray"
		if ($#rstarray >= 0 && ($st != 0 || $num != 0)); 
	}

	die "Header format error"
	    if ($#rstarray >= 0 && ($index != $rstarray[$#rstarray]->[0] + 1));
	die "Wierd rsttable" 
	    if ($st >= $en); 
	
	my $rstinfo = [ $index, $chrnam, $num, $st, $en ];
	push @{ $rsttable{$chrnam} }, $rstinfo;
	push @rstarray, $rstinfo;
	$chrlength{$chrnam} = $en;
    }
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

        if ($ele >= ${$aref}[$index][3] && $ele < ${$aref}[$index][4]) {
            return $index;
            last;
        } elsif ($ele < ${$aref}[$index][3]) {
            $top = $index - 1;
        } elsif ($ele >= ${$aref}[$index][4]) {
            $bottom = $index + 1;
        }
    }
}

1;
