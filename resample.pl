#!/usr/bin/env perl
use strict;
use warnings;

# Warning: this script, as it is, may use huges amount of RAM
# @l arrays may be tied to temporary files instead of packed strings

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/Metaheader.pm";
    use List::Util 'sum';
    use Tie::Array::Packed;
}

if ($#ARGV != 0) {
    print STDERR "usage: ./resample.pl N < input > output\n";
    exit -1;
}
my $N = pop @ARGV;

# Print the header
my $header = <>;
chomp($header);
my $metah = Metaheader->new($header);

my @rownames;
my @rowsums;
my @rowindex;
my $data = Tie::Array::Packed::IntegerNative->make();
my $cumulative = Tie::Array::Packed::IntegerNative->make();

# Load the whole matrix into memory
while (<>) {
    chomp;
    my @fields = split("\t");

    push(@rownames, shift(@fields));
    push(@rowsums, sum(@fields));
    push(@rowindex, scalar @$data);

    push(@$data, @fields);
}

# Calculate cumulative
my $sum = sum(@rowsums);

die "Error: you can resample only if N is less then the sum of the matrix"
    unless ($N <= $sum);
print $header, "\n";

my $mid = 0;
for my $i (@$data) {
    $mid += $i;
    push(@$cumulative, $mid);
}

# Search function
sub search ($) {
    my $del = shift;

    my $low = 0;
    my $high = $#$cumulative;
    my $pivot;

    do {
	$pivot = int(($low + $high)/ 2);

	if ($del >= $cumulative->[$pivot]) {
	    $low = $pivot+1;
	} else {
	    $high = $pivot;
	}

    } until (($del < $cumulative->[$pivot]) &&
	     ($pivot != 0
	      ? $del >= $cumulative->[$pivot-1] : 1));

    return $pivot;
}

my %deleted;
# Extract sum - N to delete
for my $i ($N+1..$sum) {

    my $del;
    do { $del = int(rand($sum)) } while (exists($deleted{$del}));

# Find the cell to delete
    $deleted{$del} = search($del);
}

# Delete
for my $i (values %deleted) {
    $data->[$i]--;
}

# Output the resampled matrix
my $c = 0;
for my $i (0..$#rownames) {
    print join("\t", $rownames[$i],
	       @$data[$c..($c+$#rownames-$i)]), "\n";
    $c+=($#rownames-$i+1);
}

0;
