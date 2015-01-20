#!/usr/bin/perl
use strict;
use warnings;

require 'mktemp_linux.pl';
require 'readtrimmer.pl';
require 'bowtie2align.pl';
require 'appendmap.pl'

# This the mapping pipeline (Mirny)
#

if (($#ARGV != 3) or ($#ARGV !=4)) {
	print "usage: ./map.pl fastqfile <fastqfile2> readlength leftmap rightmap\n";
	exit;
};

if ($#ARGV == 3)
    my ($fastqfilename, $readlength, $leftmapfn, $rightmapfn) = @ARGV;

my $TMPDIR="/data/temporary";

my $origreads=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq");

my $leftreads =mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq.gz");
my $rightreads=mktemp_linux("$TMPDIR/tmp.XXXXXXXX.fastq.gz");

print "Extracting fastq file\n";
my $N=int(`zcat $fastqfilename | tee $origreads | wc -l`) / 4;

print $N, " reads found\n";

my $stepl = 10;
my $minlength = 20;
my $minqual = 30;
my @leftl = ($minlength) x $N;
my @rightl = ($minlength) x $N;

#--------------------------------------------------------------------------------------------------------------------------------------
open( my $leftmap,  "| sort -g --temporary-directory=$TMPDIR | gzip > $leftmapfn");
open( my $rightmap, "| sort -g --temporary-directory=$TMPDIR | gzip > $rightmapfn");

print "Starting trimmering\n";
while (readtrimmer($origreads, $readlength, \@leftl, \@rightl, $leftreads, $rightreads) <= $readlength/2) {
    my $alignedfile = bowtie2align($leftreads);
    appendmap($leftmap, $alignedfile, \@leftl, $stepl, $minqual);
    close ($alignedfile);

    $alignedfile = bowtie2align($rightreads);
    appendmap($rightmap, $alignedfile, \@rightl, $stepl, $minqual);
    close ($alignedfile);
}

close $leftmap;
close $rightmap;

exit;
