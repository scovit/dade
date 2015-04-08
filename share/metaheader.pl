#!/usr/bin/perl
use strict;
use warnings;

# Read in from the metaheader (the restriction table)

# this should be incapsulated in a Perl (or Moose) object
# (but who cares for now)
our %metahtable;
our @metaharray;
my $metahloaded = 0;
our %metahchrlength;
our @metahchrnames;

# my %units =
#     (
#      "chr" => [["chr"]],
#      "rst" => [["index"], ["strst", "enrst"]],
#      "bp" => [["pos"], ["st", "en"]],
#      "rst%chr" => [["n"], ["chrstrst", "chrenrst"]],
#      "bp%chr" => [["chrpos"], ["chrst", "chren"]],
#     );

my %shortcuts =
    (
     "RST" => [ [ "index", "chr", "n", "st", "en" ],
		/"(\d+)~(\w+)~(\d+)~(\d+)~(\d+)"/ ];
     "PDC" => [ [ "pos" ], /(\d+)/ ],
     "BIN" => [ [ "chr", "chrpos" ], /"(\w+)~(\d+)"/ ],
    );

sub readmetaheader {
    my $header = shift;
    my $oldnum;
    my @rsttable = split("\t", $header);
    my $meta = shift @rsttable;
    if exists shortcuts{"\"$meta\""}
    for (@rsttable) {
	s/(^.|.$)//g;
	my ($index, $chrnam, $num, $st, $en) = split("~");

	unless (exists $rsttable{$chrnam}) {
	    $rsttable{$chrnam} = [];
	    push @chrnames, $chrnam;
	    die "Index errors, loaded records: $#rstarray"
		if ($#rstarray >= 0 && ($st != 0 || $num != 0));
	    $oldnum = $num - 1;
	}

	die "Header format error"
	    if ($#rstarray >= 0 &&
		($index != $rstarray[$#rstarray]->{index} + 1));
	die "Wierd rsttable, seems not ordered"
	    if ($st >= $en);
        die "Wierd rsttable, some parts seems missing"
            if ($num != ++$oldnum); 
	
	my $rstinfo = {
	    index => $index, 
	    chr => $chrnam,
	    n => $num,
	    st => $st,
	    en => $en
	};

	push @{ $rsttable{$chrnam} }, $rstinfo;
	push @rstarray, $rstinfo;
	$chrlength{$chrnam} = $en;
    }
    $rstloaded = 1;
}

# this should be a method of the class
# but for now it is basically useless (a part from map.pl)
# sub findinrst {
#     die "Should call readrsttable first" if $rstloaded == 0;

#     my $ele = $_[0]; my $chrnam = $_[1];
#     if ($chrnam eq "*") {
# 	return "*";
#     }
#     die "Chromosome not found, ", $chrnam unless exists $chrlength{$chrnam};
#     die "Read out of chromosome, ", $chrnam, " ", $ele 
# 	if $ele > $chrlength{$chrnam};

#     my $aref = $rsttable{$chrnam};

#     my $top = $#{$aref}; my $bottom = 0;
#     while (1) {
#         my $index = int(($top + $bottom)/2);

#         if ($ele >= $aref->[$index]{st} && $ele < $aref->[$index]{en}) {
#             return $index;
#             last;
#         } elsif ($ele < $aref->[$index]{st}) {
#             $top = $index - 1;
#         } elsif ($ele >= $aref->[$index]{en}) {
#             $bottom = $index + 1;
#         }
#     }
# }

1;
