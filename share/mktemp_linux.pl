
our $TMPDIR="/data/temporary"

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
