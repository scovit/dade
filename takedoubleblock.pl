#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use POSIX ":sys_wait_h";
    require "$Bin/share/mktemp_linux.pl";
}

if ($#ARGV != 1) {
    print STDERR "usage: ./takedoubleblock.pl block1 block2 < input > output\n";
    exit -1;
}
my $blockstring1 = shift @ARGV;
my $blockstring2 = shift @ARGV;

print STDERR "Creating temporary files\n";
my $tmpfile1=mktemp_linux("tmp.XXXXXXXX.mat") or
	die "Could not create temporary file";
my $tmpfile2=mktemp_linux("tmp.XXXXXXXX.mat") or
	die "Could not create temporary file";
my $tmpfile3=mktemp_linux("tmp.XXXXXXXX.mat") or
	die "Could not create temporary file";

my $pid1 = open(TO_KID1, "|-") // die "can't fork: $!";
if ($pid1 == 0) {
    # client process 1
    local @ARGV = ($blockstring1);
    local(*STDOUT);
    open(STDOUT, ">$tmpfile1") or die $!;
    die "Error in second client process" if do "$Bin/takediagblock.pl";
    die $@ if $@;
    close(STDOUT);
    exit 0;
}
my $pid2 = open(TO_KID2, "|-") // die "can't fork: $!";
if ($pid2 == 0) {
    # client process 2
    local @ARGV = ($blockstring2);
    local(*STDOUT);
    open(STDOUT, ">$tmpfile2") or die $!;
    die "Error in second client process" if do "$Bin/takediagblock.pl";
    die $@ if $@;
    close(STDOUT);
    exit 0;
}
my $pid3 = open(TO_KID3, "|-") // die "can't fork: $!";
if ($pid3 == 0) {
    # client process 3
    local @ARGV = ($blockstring1, $blockstring2);
    local(*STDOUT);
    open(STDOUT, ">$tmpfile3") or die $!;
    die "Error in third client process" if do "$Bin/takeinteractionblock.pl";
    die $@ if $@;
    close(STDOUT);
    exit 0;
}

my $dead1 = 0; my $dead2 = 0; my $dead3 = 0; my $todie = 0;
{
    local $SIG{PIPE} = sub {
	# check who is dead
	my $exitcode = 0;
	if (!$dead1 && waitpid($pid1, WNOHANG)) {
	    $dead1 = 1;
	    if ($?) {
		warn "Child 1 died unexpectedly: exit($?), dieing.." if $?;
		$todie = 1;
	    }
	}
	if ((!$dead2) && waitpid($pid2, WNOHANG)) {
	    $dead2 = 1;
	    if ($?) {
		warn "Child 2 died unexpectedly: exit($?), dieing.." if $?;
		$todie = 1;
	    }
	}
	if ((!$dead3) && waitpid($pid3, WNOHANG)) {
	    $dead3 = 1;
	    if ($?) {
		warn "Child 3 died unexpectedly: exit($?), dieing.." if $?;
		$todie = 1;
	    }
	}
    };
    while (<>) {
	last if ($dead1 && $dead2 && $dead3);
	$dead1 || print TO_KID1;
	$dead2 || print TO_KID2;
	$dead3 || print TO_KID3;
    }
}

waitpid($pid1, 0); waitpid($pid2, 0); waitpid($pid3, 0);
die if $todie;

print STDERR "Assembling\n";

open(TMP1, $tmpfile1);
open(TMP3, $tmpfile3);
while(<TMP1>) {
    chomp;
    print;
    my $ln = <TMP3>;
    die "Internal error" if (!defined $ln);
    my @r = split("\t", $ln);
    shift @r;
    print join("\t", "", @r);
}
close(TMP1); close(TMP3);
open(TMP2, $tmpfile2);
my $header = <TMP2>;
while(<TMP2>) {
    print;
}

print STDERR "Done\n";

0;
