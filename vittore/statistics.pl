#!/usr/bin/perl
use strict;
use warnings;

# Takes as input the contact list with flags; outputs statistics
#

if ($#ARGV != 0) {
	print "usage: ./statistics.pl classification\n";
	exit;
};
my ($classificationfn) = @ARGV;

use constant {
    FL_LEFT_ALIGN => 2,
    FL_RIGHT_ALIGN => 1,
    FL_LEFT_INVERSE => 8,
    FL_RIGHT_INVERSE => 4,
    FL_INVERSE => 16,
    FL_INTRA_CHR => 32,
};

sub isnot { return ($_[0] & ($_[0] ^ $_[1])); }
sub is { return ($_[0] & $_[1]); }
 
sub aligned {
    return (is(FL_LEFT_ALIGN, $_[0]) && is(FL_RIGHT_ALIGN, $_[0]));
}

sub bothunaligned {
    return (isnot(FL_LEFT_ALIGN, $_[0]) && isnot(FL_RIGHT_ALIGN, $_[0]));
}

sub single {
    return ((is(FL_LEFT_ALIGN, $_[0]) || is(FL_RIGHT_ALIGN, $_[0]))
	    && !aligned($_[0]));
}

sub dangling {
    return 
	(
	 (
	  (isnot(FL_INVERSE, $_[0]) && is(FL_RIGHT_INVERSE, $_[0]) 
	   && isnot(FL_LEFT_INVERSE, $_[0])) ||
	  (is(FL_INVERSE, $_[0]) && is(FL_LEFT_INVERSE, $_[0])
	   && isnot(FL_RIGHT_INVERSE, $_[0]))
	 ) && aligned($_[0])
	);
}

# open input files
if ($classificationfn =~ /\.gz$/) {
    open(CLASS, "gzip -d -c $classificationfn |");
} else {
    open(CLASS, "< $classificationfn");
}

my $tot = 0; my $al = 0; my $sin = 0; my $un = 0; my $dan = 0;
while (<CLASS>) {
    my @campi = split("\t");
    my $flag = $campi[1];
    $tot++;
    $al++ if aligned($flag);
    $sin++ if single($flag);
    $un++ if bothunaligned($flag);
    $dan++ if dangling($flag);
}
print "$tot Total, ", "$sin Single, "
    , "$un Both unaligned, ", "$al Aligned, of which ", "$dan Dangling", "\n";

0;
