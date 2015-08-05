#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use Data::Dumper;
    use Getopt::Long;
    use Scalar::Util qw(looks_like_number);
    use POSIX qw(floor);
    require "$Bin/share/Metaheader.pm";
}

# Takes as input matrix, output a matrix of vectors
# Makes sense after takediagonalblock on single chromosomes

my $islog = 0;
GetOptions("log" => \$islog)    # flag
  or die("Error in command line arguments\n");

if ($#ARGV != 0) {
    print STDERR "usage: ./probdecon.pl stepsize [--log] < rstmatrix"
	. " > pdcmat\n";
    exit;
}
my $steps = shift @ARGV;

die "Stepsize should be a number" if (!looks_like_number($steps));
die "Stepsize is expected to be greater than 1" if ($steps <= 1 && $islog);

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

# Read the header
my $header = <>;
chomp($header);
my $metah = Metaheader->new($header);
my @rowarray = @{ $metah->{rowinfo} };

sub getpos {
    my $i=shift;
    return ($rowarray[$i]->{pos}
	    // floor(($rowarray[$i]->{st} + $rowarray[$i]->{en})/2)
	    // die "No positional information found in header");
}

my $ipos = getpos(0);
my $enpos = getpos($#rowarray);

my $dist = $enpos - $ipos;
my $maxind = ($islog
	      ? floor(log($dist) / log($steps))
	      : floor($dist / $steps));

print join("\t", "\"PDC\"", map { binscale($_); } (0 .. $maxind)), "\n";

my $i = 0;
while(<>) {
    chomp;
    my @records = split("\t");
    my $head = shift @records;
    my $frag = $metah->metarecord($head);

#    last if ($i == $#rowarray);

    $ipos = getpos($i);
    $dist = $enpos - $ipos;
    $maxind = ($islog
               ? floor(log($dist) / log($steps))
               : floor($dist / $steps));

    # Make single restriction fragment histogram
    my @tmphisto = (0) x ($maxind+1);
    for my $j ($i .. $#rowarray) {
	my $jpos = getpos($j);
	my $hits = $records[$j-$i];
	my $ijdist = $jpos - $ipos;

	my $bin = ($islog
		   ? floor(log($ijdist) / log($steps))
		   : floor($ijdist / $steps));

	$tmphisto[$bin]+=$hits;
    }

    my @reshisto = map { $tmphisto[$_] / binsize($_) } (0 .. $maxind);

    print join("\t", "$head", @reshisto), "\n";
    $i++;
}

0;
