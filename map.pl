#!/usr/bin/env perl
use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

BEGIN {
    use FindBin '$Bin';
    use Getopt::Long;
    require "$Bin/share/mktemp_linux.pl";
    require "$Bin/share/readtrimmer.pl";
    require "$Bin/share/bowtie2align.pl";
    require "$Bin/share/appendmap.pl";
    require "$Bin/share/findinrst.pl";
}

# This the mapping pipeline (Mirny), it takes as input the sequencing data
# and output the alignemnt data
#

my $stepl = 20;
my $minlength = 20;
my $minqual = 30;
my $tmpd = "/tmp";
my $maxlength;
GetOptions("minq=i" => \$minqual,
	   "stepl=i" => \$stepl,
           "tmp=s" => \$tmpd,
	   "minl=i" => \$minlength,
	   "maxl=i" => \$maxlength
    )
  or die("Error in command line arguments\n");

if (($#ARGV != 5) and ($#ARGV != 6)) {
    print "usage: ./map.pl [--minq=30] [--minl=20] [--maxl=inf] [--stepl=20] [--tmp=/tmp] leftsource <rightsource> readlength refgenome rsttable leftmap rightmap\n";
    exit;
}

our $TMPDIR=$tmpd;
die "$TMPDIR does not exists or is not a directory"
    unless (-d $TMPDIR);
die "$TMPDIR shuld be writeable, redeable and accessible"
    . " (run: chmod 0777 $TMPDIR)"
    unless ((-r $TMPDIR) && (-w $TMPDIR) && (-x $TMPDIR));

my ($leftsource, $rightsource, $readlength, $refgenome, $rsttablefn, $leftmapfn, $rightmapfn) = 
    (undef, undef, undef, undef, undef, undef, undef);
if ($#ARGV == 6) {
    ($leftsource, $rightsource, $readlength, $refgenome, $rsttablefn, $leftmapfn, $rightmapfn) = @ARGV;
} else {
    ($leftsource, $readlength, $refgenome, $rsttablefn, $leftmapfn, $rightmapfn) = @ARGV;
}

die "Readlength should be a number" if (!looks_like_number($readlength));

################################################
# Initial file manipulations, if two file are
# used and are not gzipped then nothing is done
################################################

print "Opening input files\n";

# Check for gzipped input
if (`file $leftsource` =~ /gzip/) {
    my $tmpfile=mktemp_linux("tmp.XXXXXXXX.fastq") or
	die "Could not create temporary file";
    system("pigz -c -d $leftsource > $tmpfile");
    $leftsource = $tmpfile;
}

unless (defined $rightsource) {
    # If there is only one file, let's divide it in two
    my $tmpfile1=mktemp_linux("tmp.XXXXXXXX.fastq") or
	die "Could not create temporary file";
    my $tmpfile2=mktemp_linux("tmp.XXXXXXXX.fastq") or
	die "Could not create temporary file";
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
	my $tmpfile=mktemp_linux("tmp.XXXXXXXX.fastq") or
	die "Could not create temporary file";
	system("pigz -c -d $rightsource > $tmpfile");
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

my @leftl = ($minlength) x $N;
my @rightl = ($minlength) x $N;

# open temporary files
my $leftreads=mktemp_linux("tmp.XXXXXXXX.fastq") or
	die "Could not create temporary file";
my $rightreads=mktemp_linux("tmp.XXXXXXXX.fastq") or
	die "Could not create temporary file";

# open output files
my $gzipit =  ($leftmapfn =~ /\.gz$/) ? "| pigz" : "";
open( my $leftmap,  "| sort -g --temporary-directory=$TMPDIR $gzipit > $leftmapfn");
$gzipit =  ($rightmapfn =~ /\.gz$/) ? "| pigz" : "";
open( my $rightmap, "| sort -g --temporary-directory=$TMPDIR $gzipit > $rightmapfn");

#################################################
# The algorithm start
#################################################

print "Starting trimmering\n";
for (my $trimmered = $minlength;
     $trimmered < (($maxlength // $readlength) + $stepl);
     $trimmered += $stepl) {
    readtrimmer($leftsource, $rightsource, \@leftl, \@rightl,
		$leftreads, $rightreads);

    my $alignedfile = bowtie2align($leftreads, $refgenome);
    appendmap($leftmap, $alignedfile, \@leftl, $stepl,
	      $maxlength // $readlength, $minqual);
    close ($alignedfile);

    $alignedfile = bowtie2align($rightreads, $refgenome);
    appendmap($rightmap, $alignedfile, \@rightl, $stepl,
	      $maxlength // $readlength, $minqual);
    close ($alignedfile);
}

close $leftmap;
close $rightmap;

exit;
