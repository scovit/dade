
use constant {
    FL_LEFT_ALIGN => 2,
    FL_RIGHT_ALIGN => 1,
    FL_LEFT_INVERSE => 8,
    FL_RIGHT_INVERSE => 4,
    FL_INVERSE => 16,
    FL_INTRA_CHR => 32,
};

sub parse_class (_) {
    # die "Classification parse error" unless
    # m/^(?<INDEX> [^\t]* ) \t
    #   (?<FLAG> [^\t]* ) \t
    #   (?<LEFTCHR> [^\t]* ) \t
    #   (?<LEFTPOS> [^\t]* ) \t
    #   (?<LEFTRST> [^\t]* ) \t
    #   (?<RIGHTCHR> [^\t]* ) \t
    #   (?<RIGHTPOS> [^\t]* ) \t
    #   (?<RIGHTRST> [^\t]* ) \t
    #   (?<DIST> [^\t]* ) \t
    #   (?<RSTDIST> [^\n]* ) $/x;
    # return %+;

    my $arg = $_;
    chomp $arg;
    my @arr = split("\t", $arg);
    die "Class file format error" unless ($#arr == 9);

    my %q;
    @q{qw(INDEX FLAG LEFTCHR LEFTPOS LEFTRST RIGHTCHR RIGHTPOS RIGHTRST DIST RSTDIST)}= @arr;

    return %q;
}

sub say_class(*\%) {
    my ($file, $href) = @_;
    my %hash = %$href;

    print $file join("\t", @hash{qw(INDEX FLAG LEFTCHR LEFTPOS LEFTRST RIGHTCHR RIGHTPOS RIGHTRST DIST RSTDIST)}), "\n";
}

sub isnot { return ($_[0] & ($_[0] ^ $_[1])); }
sub is { return ($_[0] & $_[1]); }

sub aligned {
    return (is(FL_LEFT_ALIGN, $_[0]) && is(FL_RIGHT_ALIGN, $_[0]));
}

sub bothunaligned {
    return (isnot(FL_LEFT_ALIGN, $_[0]) && isnot(FL_RIGHT_ALIGN, $_[0]));
}

sub single {
    return ((is(FL_LEFT_ALIGN, $_[0]) || is(FL_RIGHT_ALIGN, $_[0]))
	    && !aligned($_[0]));
}

sub plusplus {
    return 
	(aligned($_[0]) && is(FL_INTRA_CHR, $_[0]) &&
	 (
	  (isnot(FL_INVERSE, $_[0]) &&
	   isnot(FL_LEFT_INVERSE, $_[0]) && isnot(FL_RIGHT_INVERSE, $_[0])) ||
	  (is(FL_INVERSE, $_[0]) &&
	   is(FL_LEFT_INVERSE, $_[0]) && is(FL_RIGHT_INVERSE, $_[0]))
	 ));
}

sub plusmin {
    return 
	(aligned($_[0]) && is(FL_INTRA_CHR, $_[0]) &&
	 (
	  (isnot(FL_INVERSE, $_[0]) &&
	   isnot(FL_LEFT_INVERSE, $_[0]) && is(FL_RIGHT_INVERSE, $_[0])) ||
	  (is(FL_INVERSE, $_[0]) &&
	   is(FL_LEFT_INVERSE, $_[0]) && isnot(FL_RIGHT_INVERSE, $_[0]))
	 ));
}

sub minplus {
    return 
	(aligned($_[0]) && is(FL_INTRA_CHR, $_[0]) &&
	 (
	  (isnot(FL_INVERSE, $_[0]) &&
	   is(FL_LEFT_INVERSE, $_[0]) && isnot(FL_RIGHT_INVERSE, $_[0])) ||
	  (is(FL_INVERSE, $_[0]) &&
	   isnot(FL_LEFT_INVERSE, $_[0]) && is(FL_RIGHT_INVERSE, $_[0]))
	 ));
}

sub minmin {
    return 
	(aligned($_[0]) && is(FL_INTRA_CHR, $_[0]) &&
	 (
	  (isnot(FL_INVERSE, $_[0]) &&
	   is(FL_LEFT_INVERSE, $_[0]) && is(FL_RIGHT_INVERSE, $_[0])) ||
	  (is(FL_INVERSE, $_[0]) &&
	   isnot(FL_LEFT_INVERSE, $_[0]) && isnot(FL_RIGHT_INVERSE, $_[0]))
	 ));
}

sub dangling {
    return plusmin($_[0]);
}

1;
