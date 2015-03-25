#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    use Inline C => ();
    require "$Bin/share/findinrst.pl";
    require "$Bin/share/flagdefinitions.pl";
}

# Takes as input the a PDB movie, make some random classify file
# requires Inline::C for fast looping!
# It reads from stdin, it outputs to stdout

if ($#ARGV != 2) {
	print "usage: ./pdb2classify.pl threshold rsttable psffile\n";
	exit;
};
my ($thr, $rsttablefn, $poldescrfn) = @ARGV;

# configure the chromosomes
readrsttable($rsttablefn);
our %rsttable;
our @chrnames;

my @binrst;

my $lastbin=-1;
open(my $POLDESC, "< $poldescrfn");
my $section = "null";
my $secsize = 0;
my @psfchr;
my %psfchrn;
my $nchr = 0;
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
	    push @psfchr, $rsttable{ $chrnames[$nchr] };
	    %psfchrn{ $q[2] } = $nchr;
	    $nchr++;
	}

	$secsize--;
	$section="null" unless $secsize;

    } elsif ($section eq "natom") {
	my @q = unpack("A8xA5A5A5A5A5");
	s/^\s+|\s+$//g foreach @q;

	my ($ng, $chrom, undef, $type) = @q;
	$ng--;

#	print join(", ", @q), "\n";
#       1, A, 1, TE1, T, T

	$secsize--;
	$section="null" unless $secsize;
    }	
}
close $POLDESC;

exit 0;

# read the input and output a classify file
my $m = 0;
my @x; my @y; my @z;
my $num;
sub contact_found {
    return;
    my ($i, $j) = @_;

    $num = 0;

    my $irst = $binrst[$i] -> [int(rand(@{$binrst[$i]}))];
    my $jrst = $binrst[$j] -> [int(rand(@{$binrst[$j]}))];;
    my $leftchr = $irst->[1];
    my $rightchr = $jrst->[1];

    my $flag = FL_LEFT_ALIGN | FL_RIGHT_ALIGN;
    $flag |= FL_INTRA_CHR if ($leftchr eq $rightchr);

    my $leftrst = $irst->[0];
    my $rightrst = $jrst->[0];
    my $leftpos = $irst->[3] + int(rand($irst->[4] - $irst->[3]));
    my $rightpos =  $jrst->[3] + int(rand($jrst->[4] - $jrst->[3]));

    my $distance; my $rstdist;
    if ($flag & FL_INTRA_CHR) {
	$distance = $rightpos - $leftpos;
	$rstdist = $rightrst - $leftrst;
    } else {
	$distance = "*";
	$rstdist = "*";
    }

    print $num, "\t", $flag, "\t"
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

while (<>) {
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
        for (j = i; j < n; j++) {
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
