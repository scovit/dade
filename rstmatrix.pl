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
if ($classificationfn eq '-') {
    *CLASS = *STDIN;
} elsif ($classificationfn =~ /\.gz$/) {
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
print $rsttable{"chr6"}->[843]{n}, "\n";
while (<CLASS>) {
    my @campi = split("\t");
    my (undef, $flag, $leftchr, undef, $leftrst, $rightchr,
	undef, $rightrst, undef, undef) = @campi;

    if (aligned($flag)) {
	die "Chromosome not found" unless
	    ((exists $rsttable{$leftchr}) && (exists $rsttable{$rightchr}));
	die "Restriction fragment not found (left), $leftchr, $leftrst" unless
            exists $rsttable{$leftchr}->[$leftrst];
        die "Restriction fragment not found (right), $rightchr, $rightrst" unless
            exists $rsttable{$rightchr}->[$rightrst]; 
	my $leftgrst = $rsttable{$leftchr}->[$leftrst]{index};
	my $rightgrst = $rsttable{$rightchr}->[$rightrst]{index};
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
# output
if ($matrix eq '-') {
    *OUTPUT = *STDOUT;
} else {
    my $gzipit =  ($matrix =~ /\.gz$/) ? "| gzip -c" : "";
    open(OUTPUT, "$gzipit > $matrix");
}

our @rstarray;
my @recnames;
for my $i (@rstarray) {
    push @recnames, "\"" 
	. join("~", $i->{index}, $i->{chr}, $i->{n}, $i->{st}, $i->{en})
	. "\"";
}
# header
print OUTPUT "\"RST\"", "\t", join("\t", @recnames), "\n";
my $printed=0;
my $toprint = scalar(@rstarray);
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
	$printed++;
	print OUTPUT $recnames[$oldleftgrst], "\t"
	    , join("\t",
		   @intervector[$oldleftgrst..$#intervector]), "\n";
	for my $i (0 .. $#intervector) { $intervector[$i] = 0; };
	for ( $oldleftgrst++; $oldleftgrst < $leftgrst; $oldleftgrst++) {
	    $printed++;
	    print OUTPUT $recnames[$oldleftgrst], "\t"
		, join("\t",
		       @intervector[$oldleftgrst..$#intervector]), "\n";
	}
        print STDERR "\33[2K\rElaborating rst $printed out of $toprint"
	    unless ($printed % 500);
    }

    $intervector[$rightgrst]++;
    $oldleftgrst = $leftgrst; $oldrightgrst = $rightgrst;
}
$printed++;
print OUTPUT $recnames[$oldleftgrst], "\t"
    , join("\t", @intervector[$oldleftgrst..$#intervector]), "\n";
for my $i (0 .. $#intervector) { $intervector[$i] = 0; };
for ( $oldleftgrst++; $oldleftgrst <= $#intervector; $oldleftgrst++) {
    $printed++;
    print OUTPUT $recnames[$oldleftgrst], "\t"
	, join("\t", @intervector[$oldleftgrst..$#intervector]), "\n";
}

die "Weird things happening, printed $printed out of $toprint"
    unless ($printed == $toprint);
close(ALIGN);
close(OUTPUT);
print STDERR "\33[2K\rEND\n";
0;
