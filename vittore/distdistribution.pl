#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use Scalar::Util qw(looks_like_number);
    use POSIX qw/floor/;
    use List::Util qw(sum);
    require 'share/findinrst.pl';
    require "$Bin/share/mktemp_linux.pl";
}

# Takes as input the rstmatrix; outputs histograms of
# aligned reads in function of distance, for each arm of the chromosome
#

if ($#ARGV != 3) {
	print "usage: ./rstdistribution.pl rstmatrix rsttable centromeretable"
	    , "stepsize (log|lin)\n"
	    , "  output will be named after classification with additional\n"
	    , "  extension .CHR~n.EXT\n"
	    , "  where CHR is the name of chromosome as per alignment\n"
	    , "  n can be either 1 or 2 depending on the chromosome arm"
	    , "  and EXT can be either linhist or loghist\n";
	exit;
};
my ($matrixfn, $rsttablefn, $centrofn,
    $steps, $type) = @ARGV;

die "Stepsize should be a number" if (!looks_like_number($steps));
die "Stepsize is expected to be greater than 1" if ($steps <= 1);
die "(log|lin) should be either \"log\", or \"lin\""
    if (($type ne "log") && ($type ne "lin"));
my $islog = ($type eq "log" ? 1 : 0);

# open input files
readrsttable($rsttablefn);
readcentrotable($centrofn);

my $TMPDIR="/data/temporary";

# histograms
my $histosize = 10000;
my @histogram = (0) x $histosize;
my @binscale = (0) x $histosize;
my @binsize = (0) x $histosize;
for (my $i = 0; $i < $histosize; $i++) {
    $binscale[$i] = ($islog
		      ? $steps ** ((2.0 * $i + 1.0) / 2)
		      : $steps *  ((2.0 * $i + 1.0) / 2));
    $binsize[$i] = ($islog
		    ? ($steps ** ($i + 1)) - ($steps ** $i)
		    : $steps );
}

my @intervals;
our %rsttable; our %centrotable;
for my $chr (keys %rsttable) {
    my $str = ${${$rsttable{$chr}}[0]}[0];
    my $enr = ${${$rsttable{$chr}}[$#{$rsttable{$chr}}]}[0];

    if (exists $centrotable{$chr}) {
	my $stc = ${$centrotable{$chr}}[3];
	my $enc = ${$centrotable{$chr}}[4];
	push @intervals, ["$chr~1", $str, $stc ];
	push @intervals, ["$chr~2", $enc, $enr ];
    } else {
	push @intervals, ["$chr~1", $str, $enr ];
    }
}

@intervals = sort { $a->[1] <=> $b->[1] } @intervals;
for my $int (@intervals) {
    my ($name, $st, $en) = @$int;
    print join("\t", @$int), "\n";
}
exit 0;

if ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

our @rstarray;
my $ext = ($islog ? "loghist" : "linhist");
for my $int (@intervals) {
    my ($name, $st, $en) = @$int;

    my $chrext = $name;
    $chrext =~ s/ /_/g;
    $chrext =~ s/[^A-Za-z0-9_.~]/~/g;
    
    my $normal = 0;
    for (my $line = <MATRIX>; $.-1 <= $en; $line = <MATRIX>) {
	my $i = $. - 1;
	die "Wierd things happening" if (($i < $st) || ($i > $en));
	my $ipos = floor((${$rstarray[$i]}[3] + ${$rstarray[$i]}[4])/2);
	chomp($line);
	my @records = split("\t", $line);
	my @tmphisto = (0) x $histosize;
	for my $j ($i .. $en) {
	    my $jpos = floor((${$rstarray[$j]}[3] + ${$rstarray[$j]}[4])/2);
	    my $hits = $records[$j];
	    my $dist = $jpos - $ipos;
	    
	    my $bin = ($islog
		       ? floor(log($dist) / log($steps))
		       : floor($dist / $steps));
	    
	    die "Histograms are defined too small: found bin = ", $bin, "\n"
		, 'while $histosize = ', $histosize, " , please increase me!\n"
		, '(or increase stepsize), BTW I\'m dieing now.\n'
		unless $bin < $histosize;

	    $tmphisto[$bin]+=$hits;
	}

	# normalize and make density
	my $summa = sum(@tmphisto);
	next if ($summa == 0);
	for (my $k = 0; $k < $histosize; $k++) {
	    $tmphisto[$k] = ($tmphisto[$k]
			     / $summa / $binsize[$k]);
	}
	
	# Take the sum
	for (my $k = 0; $k < $histosize; $k++) {
	    $histogram[$k] += $tmphisto[$k];
	}
	$normal++;
    }

    for (my $k = 0; $k < $histosize; $k++) {
	$histogram[$k] /= $normal;
    }

    # get maximun nonzero value
    my $maxind = $histosize;
    for (; $maxind >= 0; $maxind--) {
	last if $histogram[$maxind];
    }
    $maxind++ if $maxind != 0;

    # calculate log derivative
    my @logderivative =  (0) x $histosize;
    if ($islog) {
	my $old = $histogram[0];
	for (my $k = 1; $k < $maxind; $k++) {
	    if ($old == 0) {
		$old = $histogram[$k];
		next;
	    }
	    $logderivative[$k] = (log($histogram[$k] / $old) 
				  / log($binsize[$k - 1]));
	    $old = $histogram[$k];
	}
    }
    
    # output the histogram
    open(HISTFILE, "> $matrixfn.$chrext.$ext");
    for (my $k = 0; $k < $maxind; $k++) {
	print HISTFILE $binscale[$k], "\t", $histogram[$k];
	print HISTFILE "\t", $logderivative[$k] if $islog;
	print HISTFILE "\n";
    }
    close(HISTFILE);

    my @histogram = (0) x $histosize;
}
close(MATRIX);

0;
