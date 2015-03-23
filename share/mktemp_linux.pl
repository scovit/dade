
our $TMPDIR="/home/romain/.local/tmp";

die "$TMPDIR does not exists or is not a directory"
    unless (-d $TMPDIR);
die "$TMPDIR shuld be writeable, redeable and accessible"
    . " (run: chmod 0777 $TMPDIR)"
    unless ((-r $TMPDIR) && (-w $TMPDIR) && (-x $TMPDIR));

my @deletion_list;
sub mktemp_linux
{
    die "Temporary directory $TMPDIR doesn't exists or is not a directory"
	unless (-d $TMPDIR);
    my $fname=`mktemp $TMPDIR/$_[0]`;
    $fname =~ s/^\s+|\s+$//g ;
    push(@deletion_list, $fname);
    return $fname;
}

my $ORIG_PID = $$;
END {
    return unless $$ == $ORIG_PID;
    print "Cleaning up!\n";
    foreach (@deletion_list) {
	unlink($_) or warn "Could not unlink $origreads: $!";
    }
}

1;
