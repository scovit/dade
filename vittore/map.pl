#!/usr/bin/perl
use strict;
use warnings;

require 'share/mktemp_linux.pl';
require 'share/readtrimmer.pl';
require 'share/bowtie2align.pl';
require 'share/appendmap.pl';
require 'share/findinrst.pl';
    
# This the mapping pipeline (Mirny)
#
    
if (($#ARGV != 4) and ($#ARGV != 5)) {
    print "usage: ./map.pl leftsource <rightsource> readlength rsttable leftmap rightmap\n";
    exit;
}

my ($leftsource, $rightsource, $readlength, $rsttablefn, $leftmapfn, $rightmapfn) = (undef, undef, undef, undef, undef, undef);
if ($#ARGV == 5) {
    ($leftsource, $rightsource, $readlength, $rsttablefn, $leftmapfn, $rightmapfn) = @ARGV;
} else {
    ($leftsource, $readlength, $rsttablefn, $leftmapfn, $rightmapfn) = @ARGV;
}

my $TMPDIR="/data/temporary";

################################################
# Initial file manipulations, if two file are
# used and are not gzipped then nothing is done
################################################

print "Opening input files\n";

# Check for gzipped input
if (`file $leftsource` =~ /gzip/) {
    my $tmpfile=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq");
    system("gzip -c -d $leftsource > $tmpfile");
    $leftsource = $tmpfile;
}

unless (defined $rightsource) {
    # If there is only one file, let's divide it in two
    my $tmpfile1=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq");
    my $tmpfile2=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq");
    open OUT1, "> $tmpfile1";
    open OUT2, "> $tmpfile2";
    open IN, "< $leftsource";
    while (<IN>) {
	if ($. % 2 == 0) {
	    print OUT1 substr($_, 0, $readlength), "\n";
	    print OUT2 substr($_, $readlength, $readlength), "\n";
	} else {
	    print OUT1;
	    print OUT2;
	}
    }
    close IN; close OUT1; close OUT2;
    $leftsource = $tmpfile1;
    $rightsource = $tmpfile2;
} else {
    # Check for gzipped input
    if (`file $rightsource` =~ /gzip/) {
	my $tmpfile=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq");
	system("gzip -c -d $rightsource > $tmpfile");
	$rightsource = $tmpfile;
    }
}

print "Counting number of reads\n";
my $N=int(`cat $leftsource | wc -l`) / 4;
die "Error: leftsource and rightsource files have different number of reads"
    unless int(`cat $rightsource | wc -l`) / 4 == $N;
print $leftsource, "\n", $rightsource, "\n";
print $N, " reads found\n";

readrsttable($rsttablefn);

my $stepl = 10;
my $minlength = 20;
my $minqual = 30;
my @leftl = ($minlength) x $N;
my @rightl = ($minlength) x $N;

# open temporary files
my $leftreads=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq.gz");
my $rightreads=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq.gz");

# open output files
my $gzipit =  ($leftmapfn =~ /\.gz$/) ? "| gzip" : "";
open( my $leftmap,  "| sort -g --temporary-directory=$TMPDIR $gzipit > $leftmapfn");
$gzipit =  ($rightmapfn =~ /\.gz$/) ? "| gzip" : "";
open( my $rightmap, "| sort -g --temporary-directory=$TMPDIR $gzipit > $rightmapfn");

#################################################
# The algorithm start
#################################################

print "Starting trimmering\n";
while (1) {
    my $trimmed = readtrimmer($leftsource, $rightsource, \@leftl, \@rightl, $leftreads, $rightreads);

    my $alignedfile = bowtie2align($leftreads);
    appendmap($leftmap, $alignedfile, \@leftl, $stepl, $readlength, $minqual);
    close ($alignedfile);

    $alignedfile = bowtie2align($rightreads);
    appendmap($rightmap, $alignedfile, \@rightl, $stepl, $readlength, $minqual);
    close ($alignedfile);

    last if ($trimmed >= $readlength);
}

close $leftmap;
close $rightmap;

exit;
