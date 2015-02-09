#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/findinrst.pl";
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
            my ($NAME, $FLAG, $CHR, $POS, $MAPQ) = split("\t");
            while (${ $length }[$index] == 0) {
                $index++;
            }

            if (($MAPQ < $minq) && !($_ =~ /XS:i:[0-9-]/)) {
# Unmapped
		my $lengthvar = ${ $length }[$index];

		# if it's last iteration, just print it.
		if ($lengthvar == $rlength) {
		    print $mapfile $index, "\t", $NAME, "\t", $FLAG, "\t", $CHR
			, "\t", $POS, "\t", $MAPQ, "\t", ${ $length }[$index], "\t"
			, findinrst($POS, $CHR), "\n";
		} else {
		    my $newlength = $lengthvar + $step;
		    if ($newlength > $rlength) {
			$newlength = $rlength;
		    }
		    ${ $length }[$index] = $newlength;
		}
            } else {
# Mapped
		print $mapfile $index, "\t", $NAME, "\t", $FLAG, "\t", $CHR
		    , "\t", $POS, "\t", $MAPQ, "\t", ${ $length }[$index], "\t"
		    , findinrst($POS, $CHR), "\n";
		${ $length }[$index] = 0;
	    }
	    $index++;
	}
    }
}

1;
