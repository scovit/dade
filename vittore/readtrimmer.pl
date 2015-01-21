#!/usr/bin/perl
use strict;
use warnings;

sub readtrimmer
{
    if ($#_ != 5 ) {
	print "readtrimmer needs 6 arguments: fastqleft fastqright leftlength rigthlength outputleft.fastq.gz outputright.fastq.gz\n";
	exit;
    };
        
    my ($fastqleft, $fastqright, $leftlength, $rightlength, $outputleftfilename, $outputrightfilename)=@_;
    
    open OUTPUT1, "| gzip > $outputleftfilename";
    open OUTPUT2, "| gzip > $outputrightfilename";
    
    my $maxtrim = 0;
    my $lefttrim;
    my $righttrim;
    
    open LFILE, $fastqleft;
    open RFILE, $fastqright;
    while (<LFILE>) {
	my $A = $_;
	my $B = <RFILE>;

	my $i = ($. - 1) / 4;
	$lefttrim=${ $leftlength }[$i];
	$righttrim=${ $rightlength }[$i];
	$maxtrim = $lefttrim if $lefttrim > $maxtrim;
        $maxtrim = $righttrim if $righttrim > $maxtrim;

	if ($. % 2 == 0) {
	    if ($lefttrim != 0) {
		print OUTPUT1 substr($A,0,$lefttrim), "\n";
	    }
	    if ($righttrim != 0) {
		print OUTPUT2 substr($B,0,$righttrim), "\n";
	    }
	} else {
	    if ($lefttrim != 0) {
		print OUTPUT1;
	    }
	    if ($righttrim != 0) {
		print OUTPUT2;
	    }
	}
    }
    close LFILE;
    close RFILE;

    close OUTPUT1;
    close OUTPUT2;

    return $maxtrim;
}

1;

