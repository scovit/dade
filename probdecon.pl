#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use Scalar::Util qw(looks_like_number);
    use POSIX qw(floor);
    require "$Bin/share/findinrst.pl";
}

# Takes as input matrix, output a matrix of vectors
# Makes sense after takediagonalblock on single chromosomes

if ($#ARGV != 3) {
    print STDERR "usage: ./probdecon.pl rstmatrix stepsize (log|lin) pdcmat\n";
    exit;
}
my ($matrixfn, $steps, $type, $pdcmatrix) = @ARGV;

die "Stepsize should be a number" if (!looks_like_number($steps));
die "Stepsize is expected to be greater than 1" if ($steps <= 1);
die "(log|lin) should be either \"log\", or \"lin\""
    unless $type =~ /^log$|^lin$/;
my $islog = ($type eq "log" ? 1 : 0);

# open input files
if ($matrixfn eq '-') {
    *MATRIX = *STDIN;
} elsif ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

# histograms
sub binscale {
    my $i = shift;
    floor($islog
	  ? $steps ** ((2.0 * $i + 1.0) / 2)
	  : $steps *  ((2.0 * $i + 1.0) / 2));
}
sub binsize {
    my $i = shift;
    ($islog
     ? ($steps ** ($i + 1)) - ($steps ** $i)
     : $steps );    
}

# output
if ($pdcmatrix eq '-') {
    *OUTPUT = *STDOUT;
} else {
    my $gzipit =  ($pdcmatrix =~ /\.gz$/) ? "| gzip -c" : "";
    open(OUTPUT, "$gzipit > $pdcmatrix");
}

# Read the header
my $header = <MATRIX>;
readrsttable_from_header($header);
our @rstarray;

my $ipos = floor(($rstarray[0]->[3] + $rstarray[0]->[4])/2);
my $enpos = floor(($rstarray[$#rstarray]->[3]
		   + $rstarray[$#rstarray]->[4])/2);
my $dist = $enpos - $ipos;
my $maxind = ($islog
	   ? floor(log($dist) / log($steps))
	      : floor($dist / $steps)) - 1;

print OUTPUT "\"PDC\"", join("\t", map { binscale($_); } (0 .. $maxind)), "\n";

while(<MATRIX>) {
    chomp;
    my @records = split("\t");
    my $head = shift @records;
    $head =~ s/(^.|.$)//g;
    my @frag = split("~", $head);
    
    my $i = $frag[0] - $rstarray[0]->[0];
    die "Wierd things happening"
	if (($i < 0) || ($i > $#rstarray));
    $ipos = floor(($rstarray[$i]->[3] + $rstarray[$i]->[4])/2);
    
    # Make single restriction fragment histogram
    my @tmphisto;
    for my $j ($i+1 .. $#rstarray) {
	my $jpos = floor(($rstarray[$j]->[3] + $rstarray[$j]->[4])/2);
	my $hits = $records[$j-$i];
	my $dist = $jpos - $ipos;
	    
	my $bin = ($islog
		   ? floor(log($dist) / log($steps))
		   : floor($dist / $steps));
	    
	$tmphisto[$bin]+=$hits;
    }

    # normalize by binsize                 
    for my $k (0 .. $#tmphisto) {
	$tmphisto[$k] = (0+$tmphisto[$k])
	    / binsize($k);
    }

    $dist = $enpos - $ipos;
    $maxind = ($islog
		  ? floor(log($dist) / log($steps))
		  : floor($dist / $steps)) - 1;

    print OUTPUT "\"$head\"", join("\t", $tmphisto[0 .. $maxind]), "\n";
}
close(MATRIX);

0;
