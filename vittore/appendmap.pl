#!/usr/bin/perl
use strict;
use warnings;

sub appendmap {
    if ($#_ != 4 ) {
	print "appendmap needs 5 arguments: mapfile, samfile, length, step, minq\n";
	exit;
    };
    
    my ($mapfile, $samfile, $length, $step, $minq) = @_;

    my $index = 0;
    while (<$samfile>) {
        chomp;
        if ($_ =~ /^@/)
        {
            print $_,"\n";
        }
        else
        {
            my ($NAME, $FLAG, $CHR, $POS, $MAPQ) = split("\t");
            while (${ $length }[$index] == 0) {
                $index++;
            }

            if ($MAPQ < $minq) {
# Unmapped
		${ $length }[$index] += $step;
                $index++;
                next;
            }
# Mapped
	    print $mapfile $index, "\t", $NAME,  "\t", $FLAG, "\t", $CHR, "\t", $POS, "\t", $MAPQ, "\t", ${ $length }[$index], "\n";
            ${ $length }[$index] = 0;
            $index++;
        }
    }
}

1;
