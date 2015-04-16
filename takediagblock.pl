#!/usr/bin/perl

# Takes a block

BEGIN {
    use FindBin '$Bin';
    require "$Bin/share/Metaheader.pm";
}

if ($#ARGV != 0) {
    print STDERR "usage: ./takediagblock.pl block < input > output\n";
    exit -1;
}
my $blockstring = pop(@ARGV);

# Read the header
my $header = <>;
chomp($header);
my $metah = Metaheader->new($header);
my @rowarray = @{ $metah->{rowinfo} };

my @output = $metah->selectvector($blockstring);
die "No match" if ($#output == -1);

# print header
print join("\t", $metah->{metastring},
	         $metah->{strings}->[@output]), "\n";

my $j = 0;
while(<>) {
    last if ($#output == -1);

    if ($j == $output[0]) {
	chomp;
	my @input = split("\t");
	my $title = shift(@input);
	print join("\t", $title, @input[0..$#output]), "\n";
	shift @output;
    }
    $j++;
}

0;
