#!/usr/bin/perl
use strict;
use warnings;

# Takes a block

if ($#ARGV != 1) {
    print STDERR "usage: ./takediagblock.pl block matrix\n";
    exit;
}
my $matrixfn = pop @ARGV;
my $blockstring = pop(@ARGV);
# here compile the block
my $compiled = eval 'sub { my $_ = shift @_; return ('. $blockstring .'); }';

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
my $mattit = shift @titles;
$mattit =~ s/(^.|.$)//g; 
$mattit .= "DB";

# output, stdout
my @output;
my ($ms, $me) = (0, 0);
for my $i (0..$#titles) {
    my $currtit = $titles[$i];
    $currtit =~ s/(^.|.$)//g;
    if ($compiled->($currtit)) {
	$ms = 1;
	die "Selection is not contiguous" if $me;
	push @output, $i;
    } elsif ($ms) {
	$me = 1;
    }
}

die "No match" if ($#output == -1);

# print header
print "\"$mattit\"", "\t", join("\t", @titles[@output]), "\n";

my $j = 0;
while(<MATRIX>) {
    last if ($#output == -1);

    if ($j == $output[0]) {
	chomp;
	my @input = split("\t");
	my $title = shift(@input);
	print join("\t", $title, @input[0..$#output]), "\n";
	shift @output;
    }
    $j++;
}
close(MATRIX);

0;
