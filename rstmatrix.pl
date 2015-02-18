#!/usr/bin/perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
    require "$Bin/share/flagdefinitions.pl";
    require "$Bin/share/mktemp_linux.pl";
}

# outputs interaction matrix
#

if ($#ARGV != 2) {
	print "usage: ./rstmatrix.pl classification rsttable matrix\n";
	exit;
};
my ($classificationfn, $rsttablefn, $matrix) = @ARGV;

our $TMPDIR;

# open input files
if ($classificationfn =~ /\.gz$/) {
    open(CLASS, "gzip -d -c $classificationfn |");
} else {
    open(CLASS, "< $classificationfn");
}
readrsttable($rsttablefn);

my $alignedfn=mktemp_linux("tmp.XXXXXXXX.couples");
open(ALIGN, "| sort --parallel=8 --temporary-directory=$TMPDIR " .
     "-g -k 1 -k 2 > $alignedfn");

# Filter and sort
our %rsttable;
while (<CLASS>) {
    my @campi = split("\t");
    my (undef, $flag, $leftchr, undef, $leftrst, $rightchr,
	undef, $rightrst, undef, undef) = @campi;

    if (aligned($flag)) {
	die "Chromosome not found" unless
	    ((exists $rsttable{$leftchr}) && (exists $rsttable{$rightchr})); 
	my $leftgrst = ${ $rsttable{$leftchr} }[$leftrst][0];
	my $rightgrst = ${ $rsttable{$rightchr} }[$rightrst][0];
	if ($leftgrst < $rightgrst) {
	    print ALIGN $leftgrst, "\t", $rightgrst, "\t", $flag, "\n";
	} else {
	    print ALIGN $rightgrst, "\t", $leftgrst, "\t", $flag, "\n";
	}
    }
}
close(CLASS);
close(ALIGN);

#link($alignedfn, $alignedfn . ".dbg");

open(ALIGN, "< $alignedfn");
my $gzipit =  ($matrix =~ /\.gz$/) ? "| gzip -c" : "";
open(OUTPUT, "$gzipit > $matrix");

our @rstarray;
my @intervector = (0) x scalar(@rstarray);
my $oldleftgrst = 0; my $oldrightgrst = 0;
while (<ALIGN>) {
    my @campi = split("\t");
    my ($leftgrst, $rightgrst, $flag) = @campi;

    die "Wierd things happening"
	if (($leftgrst < $oldleftgrst) || 
	    (($rightgrst < $oldrightgrst) &&
	     ($leftgrst == $oldleftgrst)));

    if ($leftgrst != $oldleftgrst) {
	print OUTPUT join("~", @{$rstarray[$oldleftgrst]}), "\t"
	    , join("\t",
		   @intervector[$oldleftgrst..$#intervector]), "\n";
	for my $i (0 .. $#intervector) { $intervector[$i] = 0; };
	for ( $oldleftgrst++; $oldleftgrst < $leftgrst; $oldleftgrst++) {
	    print OUTPUT join("~", @{$rstarray[$oldleftgrst]}), "\t"
		, join("\t",
		       @intervector[$oldleftgrst..$#intervector]), "\n";
	}
    }

    $intervector[$rightgrst]++;
    $oldleftgrst = $leftgrst; $oldrightgrst = $rightgrst;
}

print OUTPUT join("~", @{$rstarray[$oldleftgrst]}), "\t"
    , join("\t", @intervector[$oldleftgrst..$#intervector]), "\n";
for my $i (0 .. $#intervector) { $intervector[$i] = 0; };
for ( $oldleftgrst++; $oldleftgrst <= $#intervector; $oldleftgrst++) {
    print OUTPUT join("~", @{$rstarray[$oldleftgrst]}), "\t"
	, join("\t", @intervector[$oldleftgrst..$#intervector]), "\n";
}

close(ALIGN);
close(OUTPUT);

0;
