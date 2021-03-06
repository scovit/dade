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
    my $oldnum;

    open RSTTABLE, "<", $fname or die "$fname, ", $!;
    while (<RSTTABLE>) {
	chomp;
	my ($index, $chrnam, $num, $st, $en) = split("\t", $_);

	unless (exists $rsttable{$chrnam}) {
	    $rsttable{$chrnam} = [];
	    push @chrnames, $chrnam;
	    die "Index errors" if (($st != 1) || ($num != 0));
	    $oldnum = -1;
	}

	die "File format error in $fname" if ($index != scalar(@rstarray));
	die "Wierd rsttable, seems not ordered"
	    if ($st >= $en);
        die "Wierd rsttable, some parts seems missing"
            if ($num != ++$oldnum);
	
	my $rstinfo = {
	    index => $index, 
	    chr => $chrnam,
	    n => $num,
	    st => $st,
	    en => $en
	};

	push @{ $rsttable{$chrnam} }, $rstinfo;
	push @rstarray, $rstinfo;
	$chrlength{$chrnam} = $en;
    }
    close RSTTABLE;
    $rstloaded = 1;
}

sub readrsttable_from_header {
    my $header = $_[0];
    my $oldnum;
    my @rsttable = split("\t", $header);
    shift @rsttable;
    for (@rsttable) {
	s/(^.|.$)//g;
	my ($index, $chrnam, $num, $st, $en) = split("~");

	unless (exists $rsttable{$chrnam}) {
	    $rsttable{$chrnam} = [];
	    push @chrnames, $chrnam;
	    die "Index errors, loaded records: $#rstarray"
		if ($#rstarray >= 0 && ($st != 1 || $num != 0));
	    $oldnum = $num - 1;
	}

	die "Header format error"
	    if ($#rstarray >= 0 &&
		($index != $rstarray[$#rstarray]->{index} + 1));
	die "Wierd rsttable, seems not ordered"
	    if ($st >= $en);
        die "Wierd rsttable, some parts seems missing"
            if ($num != ++$oldnum); 
	
	my $rstinfo = {
	    index => $index, 
	    chr => $chrnam,
	    n => $num,
	    st => $st,
	    en => $en
	};

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

    unless (exists $chrlength{$chrnam}) {
	warn "Chromosome not found, ", $chrnam;
	return undef;
    }
    if ($ele >= $chrlength{$chrnam}) {
	warn "Read out of chromosome, ", $chrnam, " ", $ele;
	return undef;
    }

    my $aref = $rsttable{$chrnam};

    my $top = $#{$aref}; my $bottom = 0;
    while (1) {
        my $index = int(($top + $bottom)/2);

        if ($ele >= $aref->[$index]{st} && $ele < $aref->[$index]{en}) {
            return $index;
            last;
        } elsif ($ele < $aref->[$index]{st}) {
            $top = $index - 1;
        } elsif ($ele >= $aref->[$index]{en}) {
            $bottom = $index + 1;
        }
    }
}

1;
