
use constant {
    FL_LEFT_ALIGN => 2,
    FL_RIGHT_ALIGN => 1,
    FL_LEFT_INVERSE => 8,
    FL_RIGHT_INVERSE => 4,
    FL_INVERSE => 16,
    FL_INTRA_CHR => 32,
};

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

sub plusmin {
    return 
	(aligned($_[0]) && is(FL_INTRA_CHR, $_[0]) &&
	 (
	  (isnot(FL_INVERSE, $_[0]) && is(FL_RIGHT_INVERSE, $_[0]) 
	   && isnot(FL_LEFT_INVERSE, $_[0])) ||
	  (is(FL_INVERSE, $_[0]) && is(FL_LEFT_INVERSE, $_[0])
	   && isnot(FL_RIGHT_INVERSE, $_[0]))
	 ));
}

sub dangling {
    return plusmin($_[0]);
}

1;
