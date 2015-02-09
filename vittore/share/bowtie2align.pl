

sub bowtie2align
{
    print "aligning $_[0] with index $_[1]\n";
    my $notchangeset="--reorder -q";
    my $progfile="bowtie2";
    unless (-x $progfile) {
       my $fullpath=`which $progfile`;
       chomp($fullpath);
       die "Bowtie2 not found at $progfile" unless -x $fullpath;
    }

#    my $settings="--score-min L,0.6,0.2 --very-sensitive -p 8";
    my $settings="--very-sensitive -p 14";

    my $comando="$progfile $settings $notchangeset -x $_[1] -U $_[0]";

    local *FH;
    print $comando, "\n";
    open (FH, $comando . " |") or return undef;
    return *FH;
}

1;
