#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use Scalar::Util qw(looks_like_number);
    use POSIX qw/floor/;
    use List::Util qw(sum);
    require 'share/findinrst.pl';
}

# Takes as input the rstmatrix; outputs histograms of
# aligned reads in function of distance, for each arm of the chromosome
#

if ($#ARGV != 4) {
	print "usage: ./rstdistribution.pl rstmatrix rsttable centromtable\n"
	    , "       stepsize (log|lin)\n\n"
	    , "  Output will be named after classification with additional\n"
	    , "  extension .CHR~n.EXT\n"
	    , "  where \"CHR\" is the name of chromosome as per alignment,\n"
	    , "  \"n\" can be either 1 or 2 depending on the chromosome arm\n"
	    , "  and \"EXT\" can be either linhist or loghist\n\n";
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
	my $stc = ${${$rsttable{$chr}}[${$centrotable{$chr}}[3]]}[0];
	my $enc = ${${$rsttable{$chr}}[${$centrotable{$chr}}[4]]}[0];
	push @intervals, ["$chr~1", $str, $stc ];
	push @intervals, ["$chr~2", $enc, $enr ];
    } else {
	push @intervals, ["$chr~1", $str, $enr ];
    }
}

@intervals = sort { $a->[1] <=> $b->[1] } @intervals;
print "List of rst intervals analysed:\n";
for my $int (@intervals) {
    my ($name, $st, $en) = @$int;
    print join("\t", @$int), "\n";
}

if ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

our @rstarray;
my $ext = ($islog ? "loghist" : "linhist");
my $line=<MATRIX>;
$|++;
print "Making histograms:\n";
for my $int (@intervals) {
    my ($name, $st, $en) = @$int;

    my $chrext = $name;
    $chrext =~ s/ /_/g;
    $chrext =~ s/[^A-Za-z0-9_.~]/~/g;
    print "\33[2K\rInterval $chrext";
    
    my @normal = (0) x $histosize;
    my @histogram = (0) x $histosize;
    my @variance = (0) x $histosize;
    for ( ; $.-1 <= $en; defined($line = <MATRIX>) or last) {
	my $i = $. - 1;
	die "Wierd things happening" if (($i < $st) || ($i > $en));
	my $ipos = floor((${$rstarray[$i]}[3] + ${$rstarray[$i]}[4])/2);
        my $enpos = floor((${$rstarray[$en]}[3] + ${$rstarray[$en]}[4])/2);
	chomp($line);
	my @records = split("\t", $line);

	# Make single restriction fragment histogram
	my @tmphisto = (0) x $histosize;
	for my $j ($i+1 .. $en) {
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

	my $dist = $enpos - $ipos;
	my $maxind = ($islog
		      ? floor(log($dist) / log($steps))
		      : floor($dist / $steps));

	# Histogram is the mean of histograms
	# variance will be sigma squared
	for (my $k = 0; $k < $maxind; $k++) {
	    $normal[$k]++;
	    $histogram[$k] += $tmphisto[$k];
	    $variance[$k] += $tmphisto[$k] * $tmphisto[$k];
	}
    }

    # get maximun nonzero value
    my $maxind = $histosize;
    for ( ; $maxind >= 0; $maxind--) {
        last if $histogram[$maxind];
    }
    $maxind++ if $maxind != 0;

    # get last zero before maxind 
    my $minind;
    for (my $k = 0; $k < $maxind; $k++) {
        $minind = $k unless $histogram[$minind];
    }

    for (my $k = $minind; $k < $maxind; $k++) {
	$histogram[$k] /= $normal[$k];
	$variance[$k] = $variance[$k] / $normal[$k]
	    - $histogram[$k] * $histogram[$k];
    }

    # calculate log derivative
    my @logderivative = (0) x $histosize;
    my @logdervariance = (0) x $histosize;
    if ($islog) {
	my $old = $histogram[$minind];
	my $oldvar = $variance[$minind];
	for (my $k = $minind + 1; $k < $maxind; $k++) {
	    $logderivative[$k] = (log($histogram[$k]-log($old)) 
				  / log($binsize[$k - 1]));
	    # Crappy method that ignore non-linearities
	    $logdervariance[$k] = 1.0 / (log($binsize[$k - 1])**2) * (
		1.0/($histogram[$k]**2) * $variance[$k] +
		1.0/($old**2)) * $oldvar;
	    $old = $histogram[$k]; $oldvar = $variance[$k];
	}
    }
    
    # output the histogram
    open(HISTFILE, "> $matrixfn.$chrext.$ext");
    for (my $k = $minind; $k < $maxind; $k++) {
	print HISTFILE $binscale[$k], "\t", $histogram[$k]
	    , "\t", sqrt($variance[$k]/$normal[$k]);
	print HISTFILE "\t", $logderivative[$k]
	    , "\t", sqrt($logdervariance[$k]/$normal[$k]) if $islog;
	print HISTFILE "\n";
    }
    close(HISTFILE);

}
close(MATRIX);

print "\33[2K\rEND\n";

0;
