#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
}

our %chrlength;

sub findshifts ($) {
    my $CIGAR = shift;
    my @CINFO = map { [ m/([0-9]+)([MIDNSHPX\=])/ ] } (
	$CIGAR =~ m/([0-9]+[MIDNSHPX\=])/g );
    my $LSHIFT = 0;
    my $RSHIFT = 0;

    for my $inf (@CINFO) {
	my ($value, $operator) = @$inf;
	last if ($operator eq 'M');
	$LSHIFT += $value if ($operator eq 'N');
	
    }
    for my $inf (reverse @CINFO) {
	last if ($inf->[1] eq 'M');
    }

    return ($LSHIFT, $RSHIFT);
}


sub appendmap {
    if ($#_ != 5 ) {
	print "appendmap needs 6 arguments: mapfile, samfile, length, step, readlength, minq\n";
	exit;
    };
    
    my ($mapfile, $samfile, $length, $step, $rlength, $minq) = @_;

    my $index = 0;
    while (<$samfile>) {
        chomp;
        if ($_ =~ /^@/)
        {
            print $_,"\n";
        } else {
            my ($NAME, $FLAG, $CHR, $POS, $MAPQ, $CIGAR) = split("\t");
            while ($length->[$index] == 0) {
                $index++;
            }
	    my $isambig = scalar ($_ =~ /XS:i:[0-9-]/);

            if ($MAPQ < $minq) {
# Unmapped
		my $lengthvar = $length->[$index];

		# if it's last iteration, just print it.
		if ($lengthvar == $rlength) {
		    $POS += ($length->[$index] - 1) if ($FLAG & 16);
		    $FLAG |= 4096 if $isambig;
		    my $RST = findinrst($POS, $CHR);
		    if (!defined $RST) {
			warn "Could not find RST, setting last, out: $_";
			if ($POS >= $chrlength{$CHR}) {
			    $POS = $chrlength{$CHR}-1;
			} else { die; }
			$RST = findinrst($POS, $CHR);
		    }			
		    print $mapfile join("\t", $index, $NAME, $FLAG, $CHR
					, $POS, $MAPQ, $length->[$index],
					, $RST), "\n";
		} else {
		    my $newlength = $lengthvar + $step;
		    if ($newlength > $rlength) {
			$newlength = $rlength;
		    }
		    $length->[$index] = $newlength;
		}
            } else {
# Mapped
                $FLAG |= 4096 if $isambig;
		$POS += ($length->[$index] - 1) if ($FLAG & 16);

		my $RST = findinrst($POS, $CHR);
		if (!defined $RST) {
		    warn "Could not find RST, setting last, out: $_";
		    if ($POS >= $chrlength{$CHR}) {
			$POS = $chrlength{$CHR}-1;
		    } else { die; }
		    $RST = findinrst($POS, $CHR);
		}
		print $mapfile join("\t", $index, $NAME, $FLAG, $CHR
				    , $POS, $MAPQ, $length->[$index]
				    , $RST), "\n";
		$length->[$index] = 0;
	    }
	    $index++;
	}
    }
}

1;
