
package Metaheader;

# Read in from the metaheader (the restriction table)

my %default_metaheader = (
    strings => [],
    rowinfo => [],   # @metaarray
    loaded => 0,     # $metaloaded
    interpret => [],
    haschr => 0,
    chrrows => {},   # %metatable
    chrnames => [],  # @metachrnames
    chrlength => {}  # %metachrlength
);

my %shortcuts = (
     "RST" => [ [ "index", "chr", "n", "st", "en" ],
		qr/"(\d+)~(\w+)~(\d+)~(\d+)~(\d+)"/ ],
     "PDC" => [ [ "pos" ], qr/(\d+)/ ],
     "BIN" => [ [ "chr", "chrpos" ], qr/"(\w+)~(\d+)"/ ]
);

my $sub_interpretmeta = sub {
    my $meta = shift;

    if ( $meta =~ /^\s*die\s*$/ ) {
	die "Metahader tells me that the file is not a matrix";
    };

    my $tmpret = eval($meta);

    die "Uninterpretable meta-header "
        . "(should be an array of an array and a regex)"
	unless (ref($tmpret) eq "ARRAY"
		&& scalar @{ $tmpret } == 2
		&& ref($tmpret->[0]) eq "ARRAY");
    return $tmpret;
};

my $sub_chrominfo = sub {
    my $m = shift;
    my $info = shift;
    if (exists $info->{chr}) {
	my $chrnam = $info->{chr};
	unless (exists $m->{chrrows}->{$chrnam}) {
	    $m->{chrrows}->{$chrnam} = [];
	    push @{ $m->{chrnames} }, $chrnam;
	}
	push @{ $m->{chrrows}->{$chrnam} }, $info;
	if (exists $info->{en}) {
	     $m->{chrlength}->{$chrnam} = $info->{en};
	}
    }
};

# Interpret record name
sub metarecord {
    my $self = shift;
    my $content = shift;

    my %metainfo;
    @metainfo{@{ $self->{interpret}->[0] }} =
	$content =~ $self->{interpret}->[1];
    return \%metainfo;
}

# This is supposed to be the creator of the class
sub new {
    my $classname = shift;
    my $header = shift;
    my $oldnum;
    my @hcolumns = split("\t", $header);
    my $metastring = shift @hcolumns;
    my ($meta) = $metastring =~ /^"(.+)"$|^(.+)$/;

    my %m = %default_metaheader;
    my $self = \%m;

    $self->{strings} = \@hcolumns;
    $self->{metastring} = $metastring;
    $self->{interpret} = $shortcuts{$meta} // $sub_interpretmeta->($meta);

    for my $col (@hcolumns) {
	my $metainfo = metarecord($self, $col);
	push @{ $self->{rowinfo} }, $metainfo;

	if (exists $metainfo->{chr}) {
	    $self->{haschr} = 1;
	    $sub_chrominfo->($self, $metainfo);
	}

    }
    $self->{loaded} = 1;
    return bless $self, $classname;
}

sub findinheader {
    my $self = shift;
    die "Should load object first" if $self->{loaded} == 0;
    die "Findinheader works only with chromosome specifying headers" 
	if $self->{haschr} == 0;

    my $ele = shift; my $chrnam = shift;
    if ($chrnam eq "*") {
	return "*";
    }
    die "Chromosome not found, ", $chrnam unless
	exists $self->{chrlength}->{$chrnam};
    die "Read out of chromosome, ", $chrnam, " ", $ele 
	if $ele > $self->{chrlength}->{$chrnam};

    my $aref = $self->{chrrows}->{$chrnam};
    die "Findinheader works only if st and en fields are specified" 
	unless (exists $aref->[0]->{st} && exists $aref->[0]->{en});

    my $top = $#{$aref}; my $bottom = 0;
    while (1) {
        my $index = int(($top + $bottom)/2);

        if ($ele >= $aref->[$index]->{st} && $ele < $aref->[$index]->{en}) {
            return $index;
            last;
        } elsif ($ele < $aref->[$index]->{st}) {
            $top = $index - 1;
        } elsif ($ele >= $aref->[$index]->{en}) {
            $bottom = $index + 1;
        }
    }
}

1;
