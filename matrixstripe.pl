#!/usr/bin/env perl
use strict;
use warnings;

# Warning: this script, as it is, may use huges amount of RAM
# @l arrays may be tied to temporary files

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/Metaheader.pm";
}

if ($#ARGV != 0) {
    print STDERR "usage: ./matrixstrip.pl block < input > output\n";
    exit -1;
}
my $blockstring = pop @ARGV;

# Read the header
my $header = <>;
chomp($header);
my $metah = Metaheader->new($header);
my @rowarray = @{ $metah->{rowinfo} };

print join("\t", "\"die\"", @{ $metah->{strings} }),"\n";

# here compile the block
my $compiled = eval 
    'sub {
       local $_ = shift; local @_ = split("~");
       local %_ = %{ $metah->metarecord($_) };
       '. $blockstring .'
     }';
die $@ unless($compiled);

# output, stdout
my @output;
my @l;
my ($ms, $me) = (0, 0);
for my $i (0..$#{ $metah->{strings} }) {
    if ($compiled->($metah->{strings}->[$i])) {
	$ms = 1;
	die "Selection is not contiguous" if $me;
	push @output, $i;
	push @l, [];
    } elsif ($ms) {
	$me = 1;
    }
}

my $j = 0;
while (<>) {
    last if ($#output == -1);

    chomp;
    my @r=split("\t");
    my $head=shift @r;

    if ($j == $output[0]) {

	print join("\t", $head, @{$l[0]}, @r),"\n";

	shift @output;
	shift @l;
    }

    for my $i (0..$#output) {
	push @{$l[$i]}, $r[$output[$i]];
    }

    $j++;
}
