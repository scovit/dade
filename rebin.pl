#!/usr/bin/env perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);
use POSIX qw/floor/;
use List::Util qw(any);

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
}

# Takes as input the rstmatrix, rebin into genomic distance

if ($#ARGV != 3) {
	print "usage: ./rebin.pl matrix rsttable binsize(bp) binmatrix\n";
	exit;
};
my ($matrixfn, $rsttablefn, $binsize, $binmatrix) = @ARGV;

die "Binsize should be a number" if (!looks_like_number($binsize));

readrsttable($rsttablefn);

# Make the bin table
our @rstarray;
my @bins;
my @bintitle;
{
    my $binstartp = 0;
    my $currchr = "-1";
    for my $rst (@rstarray) {
	my $rstpos = floor(($rst->{st} + $rst->{en})/2);
	my $chrnam = $rst->{chr};

	# new chromosome?
	if ($chrnam ne $currchr) {
	    push @bins, [];
	    my $binpos = floor($binsize/2);
	    push @bintitle, "\"$chrnam~$binpos\"";
	    $currchr = $chrnam;
	    $binstartp = 0;
	}
	# empty bins if no rst is there
	while ($binstartp + $binsize < $rstpos) {
	    push @bins, [];
	    $binstartp += $binsize;
	    my $binpos = $binstartp + floor($binsize / 2);
	    push @bintitle, "\"$chrnam~$binpos\"";
	}

	push @{ $bins[$#bins] }, $rst->{index};
    }
}

my $MATRIX;
# open input files
if ($matrixfn eq '-') {
    $MATRIX = *STDIN;
} elsif ($matrixfn =~ /\.gz$/) {
    open($MATRIX, "gzip -d -c $matrixfn |");
} else {
    open($MATRIX, "< $matrixfn");
}
# rebin
# output
if ($binmatrix eq '-') {
    *OUTPUT = *STDOUT;
} else {
    my $gzipit =  ($binmatrix =~ /\.gz$/) ? "| gzip -c" : "";
    open(OUTPUT, "$gzipit > $binmatrix");
}
# Read the header
my $header = <$MATRIX>;

# Read a line from the matrix, return content and fragment number
sub mreadline {
    my $file = $_[0];
    my $line = <$file>;
    return undef, undef unless (defined $line);
    chomp($line);
    my @input = split("\t", $line);
    my $head = shift(@input);
    $head =~ s/(^.|.$)//g;
    my @frag = split("~", $head);
    die "Wrong matrix format" if (!looks_like_number($frag[0]));
    return \@input, $frag[0];
};
my ($input, $inputln) = mreadline($MATRIX);
die "File format error" if (!(defined $input) || ($#$input < 0));
my $lastln = $inputln + $#$input;

# Get the first and last bin
my $binstart = -1; my $binend = -1;
for (my $i = 0; $i <= $#bins; $i++) {
    $binstart = $i if (any { $_ == $inputln } @{$bins[$i]});
    $binend = $i if (any { $_ == $lastln } @{$bins[$i]});
}
die "Didn't find start and end bin, weird" if (($binstart < 0) ||
					       ($binend < 0));

# Print the header
print OUTPUT "\"BIN\"", "\t"
    , join("\t", @bintitle[$binstart..$binend]), "\n";

for my $binan ($binstart..$binend) {
    my @inputs;
    my @inputsln;
    my @output = (0) x ($binend - $binan + 1);

    print STDERR "\33[2K\rElaborating bin $binan out of $#bins";

    # Load a whole row bin into memory (note, the script eats an
    # amount of memory proportional to the bin size)
    for my $i (0 .. $#{$bins[$binan]}) {
	# Do some checks
	if (defined $input) {
	    while (($binan == $binstart) &&
		   (${$bins[$binan]}[$i] != $inputln)) { $i++; };
	    die "Row is lost, matrix should be a full diagonal block"
		if (${$bins[$binan]}[$i] != $inputln);

	    push @inputs, $input;
	    push @inputsln, $inputln;
	    ($input, $inputln) = mreadline($MATRIX);
	} elsif ($binan != $binend) {
	    die "Sudden end of file, maybe matrix was not cut square?"
	}
    }

    # column index
    for my $binbn ($binan .. $binend) {
	for my $j (0 .. $#inputs) {
	    for my $i (@{$bins[$binbn]}) {
		next if ($binbn == $binan && $inputsln[$j] > $i);
		my $coln = $i - $inputsln[$j];
#		print join("\t", $binan, $binbn, $inputsln[$j], $i, $coln), "\n";
		if (!(defined ${$inputs[$j]}[ $coln ])
		   && ($binbn != $binend)) {
		    die "Missing columns, $binan, $binbn ($binstart, $binend)";
		} elsif ( defined ${$inputs[$j]}[ $coln ] ) {
		    $output[$binbn - $binan] += ${$inputs[$j]}[ $coln ];
		}
	    }
	}
    }
    
    print OUTPUT $bintitle[$binan], "\t", join("\t", @output), "\n";
    last unless defined $input;
}
close(OUTPUT);
close($MATRIX);

print STDERR "\33[2K\rEND\n";

0;
