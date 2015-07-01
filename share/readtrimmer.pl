#!/usr/bin/perl
use strict;
use warnings;

sub trimthread {
    open OUTPUT, "> $_[0]";
    open FILE, $_[1];
    my $length = $_[2];

    my $maxtrim = 0;
    while (<FILE>) {
	my $i = ($. - 1) / 4;

	my $trim = $length->[$i];
	$maxtrim = $trim if $trim > $maxtrim;

	if ($. % 2 == 0) {
	    if ($trim != 0) {
		print OUTPUT substr($_,0,$trim), "\n";
	    }
	} else {
	    if ($trim != 0) {
		print OUTPUT;
	    }
	}
    }
    close FILE;
    close OUTPUT;
};

sub readtrimmer
{
    if ($#_ != 5 ) {
	print "readtrimmer needs 6 arguments: fastqleft fastqright leftlength rigthlength outputleft.fastq.gz outputright.fastq.gz\n";
	exit;
    };
        
    my ($fastqleft, $fastqright, $leftlength, $rightlength, $outputleftfilename, $outputrightfilename)=@_;

    my $pid = fork;
    if (!defined $pid) {
	die "Cannot fork: $!";
    }
    elsif ($pid == 0) {
	# client process
	trimthread($outputrightfilename, $fastqright, $rightlength);
	exit 0;
    }
    else {
	# parent process
	trimthread($outputleftfilename, $fastqleft, $leftlength);
	waitpid $pid, 0;
    }

}

1;

