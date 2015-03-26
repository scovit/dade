#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use Inline C => ();
    use Statistics::R;
    use POSIX qw/floor/;
    require "$Bin/share/findinrst.pl";
    require "$Bin/share/flagdefinitions.pl";
}

# Takes as input the a PDB movie, make some random classify file
# It reads from stdin, it outputs to stdout
#
#                               REQUIRES
# Inline::C for fast looping.
# Statistics::R for Coefficient of determination calculation.
#

if ($#ARGV != 3) {
	print "usage: ./pdb2classify.pl threshold rsttable"
	                            , " intervalli psffile\n";
	exit;
};
my ($thr, $rsttablefn, $intervallifn, $poldescrfn) = @ARGV;

### configure the chromosomes (these following three scopes of code)

readrsttable($rsttablefn);
our %rsttable;
our @chrnames;
our %chrlength;

# Main task of this three first scopes of code will be to compile this
# single variable, which relates beads (bins) to restriction fragments
my @binrst;

# Read polymer simulation description (1st scope)
my @psfchrn;
my %psfbranch;
my %psfbins;
{
    open(my $POLDESC, "< $poldescrfn");
    my $section = "null";
    my $secsize = 0;
    while (<$POLDESC>) {
	chomp;
	if ($section eq "null") {
	    next if length() < 9;
	    my @q = split;
	    next if @q < 2;

	    if ($q[1] =~ /^\!NTITLE\b/) {
		$section="ntitle";
		$secsize=$q[0];

	    } elsif ($q[1] =~ /^\!NATOM\b/) {
		$section="natom";
		$secsize=$q[0];
	    }

	} elsif ($section eq "ntitle") {
	    my @q = split;

	    if ($q[1] eq "segment") {
		push @psfchrn, $q[2];
		$psfbins{ $q[2] . "~" . 0 } = [];
		$psfbranch{ $q[2] } = 0;
	    }

	    $secsize--;
	    $section="null" unless $secsize;

	} elsif ($section eq "natom") {
	    my @q = unpack("A8xA5A5A5A5A5");
	    s/^\s+|\s+$//g foreach @q;

	    my ($ng, $chrom, undef, $type) = @q;
	    $ng--;
	    $binrst[$ng] = [];

	     if ($type eq "CE2") {
		 $psfbranch{ $chrom }++;
		 $psfbins{ $chrom . "~" . $psfbranch{ $chrom } } = [];
	     }

	     if ($type eq "EDG") {
		 push @{$psfbins{ $chrom . "~" . $psfbranch{ $chrom } }}, $ng;
	     }

	     $secsize--;
	     $section="null" unless $secsize;
	 }
     }
     close $POLDESC;
 }

 # Setup corrispondency between chromosomal arms (second scope)
 my %interv;
 {
     my $R = Statistics::R->new();
     open(my $INTER, "< $intervallifn");
     my $cchr = 0;
     my %ninterv;

     while(<$INTER>) {
	 chomp;
	 my @q = split("\t");
	 my ($cnam, $csecl) = ($q[0] =~ /(chr\d+)([a-z])/g);

	 next unless defined $csecl;
	 if ($cnam ne $chrnames[$cchr]) {
	     next unless $cnam eq $chrnames[$cchr+1];
	     $cchr++;
	 }
	 $csecl = ord($csecl) - ord("a");

	 my ($stpoint) = $q[1] =~ />\s*(\d+)/;
	 my ($endpoint) = $q[1] =~ /<\s*(\d+)/;
	 $stpoint //= 0;
	 $endpoint //= $chrlength{ $cnam };
	 my $bplength = $endpoint - $stpoint;
	 die "Negative arm length" if $bplength < 0;

	 my $binlength = @{$psfbins{ $psfchrn[$cchr]."~".$csecl }};

	 $ninterv{ $psfchrn[$cchr] } = $csecl;
	 $interv{ $psfchrn[$cchr]."~".$csecl } = 
	     { n => $cchr,
	       nam => $cnam,
	       sec => $csecl,
	       bpst => $stpoint,
	       bpen => $endpoint,
	       bplen => $bplength,
	       binlen => $binlength,
	       bins => $psfbins{ $psfchrn[$cchr]."~".$csecl }
	     };

     }
     close $INTER;

     # Invert chromosomal arms if needed
     my @x;
     my @y;
     for my $i (@psfchrn) {
	 for my $j (0, 1) {
	     push @x, $interv{ $i."~".$j }{bplen};
	     push @y, $interv{ $i."~".$j }{binlen};
	 }
     }
     $R->set( 'x', \@x ); $R->set( 'y', \@y );
     $R->run("res<-lm(x ~ y)");
     my $rres=$R->get('summary(res)$r.squared');

     if ($rres < 0.9) {
     	 warn "Polymer seems to not represent data (R^2 = $rres), "
     	     ."trying to reversing arms.";
     	 for my $i (@psfchrn) {
     	     my @oldorder = (0..$ninterv{$i});
     	     my @neworder = reverse @oldorder;
     	     for my $j (0..$#neworder/2) {
     		 ( $interv{ $i."~".$oldorder[$j] }{binlen},
     		   $interv{ $i."~".$neworder[$j] }{binlen},
     		   $interv{ $i."~".$oldorder[$j] }{bins},
     		   $interv{ $i."~".$neworder[$j] }{bins} ) =
     		       ( $interv{ $i."~".$neworder[$j] }{binlen},
     			 $interv{ $i."~".$oldorder[$j] }{binlen},
     			 $interv{ $i."~".$neworder[$j] }{bins},
     			 $interv{ $i."~".$oldorder[$j] }{bins} );
     	     }
     	 }
     	 $#x = -1; $#y = -1;
     	 for my $i (@psfchrn) {
     	     for my $j (0, 1) {
     		 push @x, $interv{ $i."~".$j }{bplen};
     		 push @y, $interv{ $i."~".$j }{binlen};
     	     }
     	 }
     	 $R->set( 'x', \@x ); $R->set( 'y', \@y );
     	 $R->run("res<-lm(x ~ y);");
     	 $rres=$R->get('summary(res)$r.squared');
     	 die "Could not fix the situation (R^2 = $rres)..." if $rres < 0.9;
     	 print STDERR "Fixed (R^2 = $rres)\n";
     };
 }

 # Assign rsts to beads (bins) (third scope)
 for my $arm (values %interv) {

     my $binsize = $arm->{bplen} / $arm->{binlen};

     my @rstarr = grep { 
	 ($_->{st} >= $arm->{bpst}) &&
	     ($_->{en} < $arm->{bpen})
     } @{$rsttable{ $arm->{nam} }};

     my $binstartp = $arm->{bpst};
     my $currbin = shift @{$arm->{bins}};
     for my $rst (@rstarr) {

	 my $rstpos = floor(($rst->{st} + $rst->{en})/2);

	 # empty bins if no rst is there
	 while ($binstartp + $binsize < $rstpos) {
	     $binstartp += $binsize;
	     $currbin = shift @{$arm->{bins}};
	 }
	 unless ($currbin) {
	     warn "Some rst are lost ";
	     last;
	 };

	 push @{$binrst[$currbin]}, $rst;
	 # print join("\t", $arm->{nam}, $arm->{sec},
	 # 	    $rst->{index}, $rst->{chr}, $rst->{st},
	 # 	    $currbin), "\n";
    }

}

### Start analyzing polymer trajectory

# read the input and output a classify file
my $m = 0;
my @x; my @y; my @z;
my $num;
sub contact_found {
    my ($i, $j) = @_;

    $num = 0;

    return if (@{$binrst[$i]} == 0) || (@{$binrst[$j]} == 0); 

    my $irst = $binrst[$i] -> [int(rand(@{$binrst[$i]}))];
    my $jrst = $binrst[$j] -> [int(rand(@{$binrst[$j]}))];;
    my $leftchr = $irst->{chr};
    my $rightchr = $jrst->{chr};

    my $flag = FL_LEFT_ALIGN | FL_RIGHT_ALIGN;
    $flag |= FL_INTRA_CHR if ($leftchr eq $rightchr);

    my $leftrst = $irst->{index};
    my $rightrst = $jrst->{index};
    my $leftpos = $irst->{st} + int(rand($irst->{en} - $irst->{st}));
    my $rightpos =  $jrst->{st} + int(rand($jrst->{en} - $jrst->{st}));

    my $distance; my $rstdist;
    if ($flag & FL_INTRA_CHR) {
	$distance = $rightpos - $leftpos;
	$rstdist = $rightrst - $leftrst;
    } else {
	$distance = "*";
	$rstdist = "*";
    }

    print STDOUT $num, "\t", $flag, "\t"
	, $leftchr, "\t", $leftpos, "\t", $leftrst, "\t"
	, $rightchr, "\t", $rightpos, "\t", $rightrst, "\t"
	, $distance, "\t", $rstdist, "\n";

    $num++;
}

sub loop_over_beads {
    die "Internal loop takes 3 arguments" if @_ != 3;

    my $n = scalar @{$_[0]};
    die "Weird arrays content"
	if ($n != scalar @{$_[1]}
	    || $n != scalar @{$_[2]});

    my $packedx = pack "d*", @{$_[0]};
    my $packedy = pack "d*", @{$_[1]};
    my $packedz = pack "d*", @{$_[2]};

    return c_loop_over_beads($thr,
			     \&contact_found,
			     $packedx, $packedx, $packedx);
}


# Main loop
while (<STDIN>) {
    chomp;

    if (/^ATOM\b/) {
	my @q = unpack("a6a5a3a6a2a4a4a8a8a8a6a6a6a3");
	s/^\s+|\s+$//g foreach @q;

	my $ng = $q[1] - 1;
	$x[$ng] = $q[7]; $y[$ng] = $q[8]; $z[$ng] = $q[9];

    } elsif (/^END\b/) {
	my $found = loop_over_beads(\@x, \@y, \@z);
	my $total = @x * (@x + 1) / 2;
	print STDERR "Configuration $m; found $found contacts out of ",
	    , "$total possible (", int($found/$total*100), "%)\n";
	$m++;
    }
}

0;


# C triangulation code

__END__
__C__

SV *callback;
static inline void contact(int i, int j) {
   dSP;
   ENTER;
   SAVETMPS;

   PUSHMARK(SP);
   XPUSHs(sv_2mortal(newSVuv(i)));
   XPUSHs(sv_2mortal(newSVuv(j)));
   PUTBACK;

   call_sv(callback, G_DISCARD);

   FREETMPS;
   LEAVE;        
}

void c_loop_over_beads(SV* name1, ...) {
    Inline_Stack_Vars;
    unsigned int n;
    double thr, dist;
    double *x; double *y; double *z;
    int i, j;
    unsigned int count = 0;

    if (Inline_Stack_Items != 5)
	croak("Internal loop takes 5 arguments");

    thr = SvNV(Inline_Stack_Item(0));
    callback = Inline_Stack_Item(1);
    x = (double *)SvPV_nolen(Inline_Stack_Item(2));
    y = (double *)SvPV_nolen(Inline_Stack_Item(3));
    z = (double *)SvPV(Inline_Stack_Item(4), n);
    n /= sizeof(double);

    for (i = 0; i < n; i++) {
        for (j = i + 1; j < n; j++) {
            dist = (x[i] - x[j])*(x[i] - x[j]) +
                   (y[i] - y[j])*(y[i] - y[j]) + 
                   (z[i] - z[j])*(z[i] - z[j]);

            if (dist < thr) {
                count++;
                contact(i, j);
            }
        }
    }

    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSVuv(count)));
    Inline_Stack_Done;
    Inline_Stack_Return(1);
}
