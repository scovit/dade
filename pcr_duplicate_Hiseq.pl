#!/usr/bin/env perl

use Getopt::Long;

# 19/03/2015
# Take two fastq files together and revove the PCR duplicates i.e whose ends have exactly the same sequences.
# and remove tags of 10 bp 

my $remove = 10;
my $cmpr   = 20;
my $skip   = 0;
GetOptions("remove=i" => \$remove,
	   "cmpr=i"   => \$compr,
           "skip=i"   => \$skip)
    or die("Error in command line arguments\n");

if ($#ARGV != 3) {
    print "usage: ./pcr_duplicate.pl [--cmpr=20] [--remove=10] [--skip=0] leftsource rightsource leftout rightout\n";
    exit;
}

my ($leftsource, $rightsource, $leftout, $rightout) = @ARGV;

# open input files
open(LEFT, "< $leftsource");
open(RIGHT, "< $rightsource");

# open output files
open(LOUT, "> $leftout");
open(ROUT, "> $rightout");

my $f = 0;
my %group;
while (1) {

    my $line_before1 = <LEFT>;
    defined $line_before1 or last; 
    my $line_before2 = <RIGHT>;
    defined $line_before2 or die "Unexpected line ending";

    my $line1 = <LEFT> or die "Unexpected line ending";
    my $line2 = <RIGHT> or die "Unexpected line ending";
    my $word1 = substr $line1, $skip, $cmpr;
    my $word2 = substr $line2, $skip, $cmpr;

    if (exists($group{$word1.$word2}) || exists($group{$word2.$word1}) || ($word1 eq $word2)) {
        <LEFT> or die "Unexpected line ending";
        <RIGHT> or die "Unexpected line ending";
        <LEFT> or die "Unexpected line ending";
        <RIGHT> or die "Unexpected line ending";
    } else {
	$group{$word1.$word2} = 1;
      
	print LOUT $line_before1, substr($line1, $remove);
	print ROUT $line_before2, substr($line2, $remove);
	$line1 = <LEFT> or die "Unexpected line ending";
	$line2 = <RIGHT> or die "Unexpected line ending";
	print LOUT $line1;
	print ROUT $line2;
        $line1 = <LEFT> or die "Unexpected line ending";
        $line2 = <RIGHT> or die "Unexpected line ending";
	print LOUT substr($line1, $remove);
	print ROUT substr($line2, $remove);
    }
    $f++;
}
print STDERR "There are $f reads parsed.\n";
close(LEFT); close(RIGHT); close(LOUT); close(ROUT);

0;

