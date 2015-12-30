#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use POSIX ":sys_wait_h";
    use Scalar::Util qw(looks_like_number);
    use List::MoreUtils qw(all);
    require "$Bin/share/mktemp_linux.pl";
}

if ($#ARGV < 1) {
    print STDERR "usage: ./takeblocks.pl N block1 block2 .. blockN < input > output\n";
    exit -1;
}
my $N = shift @ARGV;
die "N should be a number" if (!looks_like_number($N));

my @blockstrings = @ARGV;
die "Number of blocks different from N" if (scalar(@blockstrings) != $N);

# Check if stdout is a pipe
my $nopipe = (-p STDOUT ? 0 : 1);

my @pids;
my @tmpfiles;
my @to_kids;
my $nprocs = $N+$N*($N-1)/2;
print STDERR "Starting $nprocs parallel jobs and temporary files\n"
    if $nopipe;

for my $i (0..$N-1) {
    my $block=$blockstrings[$i];
    my $tmpfile = mktemp_linux("tmp.XXXXXXXX.mat") or
 	die "Could not create temporary file";
    my $pid = open(my $to_kid, "|-") // die "can't fork: $!";
    if ($pid == 0) {
	local @ARGV = ($block);
	local(*STDOUT);
	open(STDOUT, ">$tmpfile") or die $!;
	die "Error in client process for block: $block" if do "$Bin/takediagblock.pl";
	die $@ if $@;
	close(STDOUT);
	exit 0;
    }
    push @pids, $pid;
    push @tmpfiles, $tmpfile;
    push @to_kids, $to_kid;

    for my $j ($i+1..$N-1) {
	my $interaction = $blockstrings[$j];
	my $tmpfilei = mktemp_linux("tmp.XXXXXXXX.mat") or
	    die "Could not create temporary file";
	my $pidi = open(my $to_kidi, "|-") // die "can't fork: $!";
	if ($pidi == 0) {
	    local @ARGV = ($block, $interaction);
	    local(*STDOUT);
	    open(STDOUT, ">$tmpfilei") or die $!;
	    die "Error in client process for interaction: $block, $interaction"
		if do "$Bin/takeinteractionblock.pl";
	    die $@ if $@;
	    close(STDOUT);
	    exit 0;
	}
	push @pids, $pidi;
	push @tmpfiles, $tmpfilei;
	push @to_kids, $to_kidi;
    }
}

die "Internal error" unless
    scalar(@pids) == $nprocs &&
    scalar(@tmpfiles) == $nprocs &&
    scalar(@to_kids) == $nprocs;

my @dead = (0) x $nprocs;
my $todie = 0;
{
    local $SIG{PIPE} = sub {
	# check who is dead
	my $exitcode = 0;
        for my $i (0..$nprocs-1) {
	    if (!$dead[$i] && waitpid($pids[$i], WNOHANG)) {
		$dead[$i] = 1;
		if ($?) {
		    warn "Child $i died unexpectedly: exit($?), dieing.." if $?;
		    $todie = 1;
		}
                close($to_kids[$i]);
	    }
	}
    };

    while (my $line = <STDIN>) {
	next if all { $_ == 1 } (@dead);
	for my $i (0..$nprocs-1) {
	    $dead[$i] || print { $to_kids[$i] } $line;
	}
    }
}

for my $i (0..$nprocs-1) {
    close($to_kids[$i]) unless $dead[$i];
}
waitpid($_, 0) for (@pids);
die if $todie;

print STDERR "Assembling\n"
    if $nopipe;

for my $i (0..$N-1) {
    open(my $blockfile, shift(@tmpfiles));

    my @interfiles;
    for my $j ($i+1..$N-1) {
	open(my $interfile, shift(@tmpfiles));
	push @interfiles, $interfile;
    }

    unless ($i == 0) {
	my $header = <$blockfile>;
	$header = <$_> for (@interfiles);
    }

    while(<$blockfile>) {
	chomp;
	print;
	for my $f (@interfiles) {
	    my $ln = <$f>;
	    die "Internal error" if (!defined $ln);
	    chomp($ln);
	    my @r = split("\t", $ln);
	    shift @r;
	    print join("\t", "", @r);
	}
	print "\n";
    }
    close($blockfile);
    close($_) for (@interfiles);
}

die "Internal error" unless (scalar(@tmpfiles) == 0);

$|++;
print STDERR "Done\n"
    if $nopipe;

0;
