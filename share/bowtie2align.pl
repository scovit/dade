

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

# This disables gaps
    my $settings="--very-sensitive --rdg 500,3 --rfg 500,3 -p 14";

    my $comando="$progfile $settings $notchangeset -x $_[1] -U $_[0]";

    local *FH;
    print $comando, "\n";
    open (FH, $comando . " |") or return undef;
    return *FH;
}

1;
