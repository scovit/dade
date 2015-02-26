#!/usr/bin/perl
use strict;
use warnings;

# Takes a block

if ($#ARGV != 1) {
    print STDERR "usage: ./takediagblock.pl regex matrix\n";
    exit;
}
my $matrixfn = pop @ARGV;
# here precompile the regex
my $regex = qr/pop(@ARGV)/;

# open input files (files will be readed two times)
if ($matrixfn eq '-') {
    *MATRIX = *STDIN;
} elsif ($matrixfn =~ /\.gz$/) {
    open(MATRIX, "gzip -d -c $matrixfn |");
} else {
    open(MATRIX, "< $matrixfn");
}

my $header = <MATRIX>;
chomp($header);
my @titles = split("\t", $header);
shift @titles; 

# output, stdout
my @output;
my ($ms, $me) = (0, 0);
for $i (0..$#titles) {
    if ($titles[$i] ~= $regex) {
	$ms = 1;
	die "Selection is not contiguous" if $me;
	push @output, $i;
    } elsif $ms {
	$me = 1;
    }
}

seek MATRIX, 0, 0;
my $j = 0;
while(<MATRIX>) {
    last if ($#output == -1);
    
    if ($j == $output[0]) {
	chomp;
	my @input = split("\t");
	my $title = shift(@input);
	print join("\t", $title, @input[0..$#output]);
	shift @output;
    }
    $j++;
}
close(MATRIX);

0;
