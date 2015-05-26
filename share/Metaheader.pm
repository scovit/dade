
package Metaheader;

# Read in from the metaheader (the restriction table)

my %default_metaheader = (
    metastring => "",
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
    "RST" => qr/\"
          (?<index> \d+ ) \~ 
          (?<chr> \w* ) \~
          (?<n> \d+ ) \~
          (?<st> \d+ ) \~
          (?<en> \d+ )
              \"/x,
    "PDC" => qr/(?<pos> \d+ )/x,
    "BIN" => qr/\"(?<chr> \w+ ) \~ (?<chrpos> \d+ ) \"/x
    );

my $sub_interpretmeta = sub {
    my $meta = shift;

    if ( $meta =~ /^\s*die\s*$/ ) {
	die "Metahader tells me that the file is not a matrix";
    };

    my $tmpret = eval($meta);

    die "Uninterpretable meta-header "
        . "(should be a regex or a shortcut)"
	unless (ref($tmpret) eq "Regexp");
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

    die "Could not parse Metaheader" unless
	$content =~ $self->{interpret};

    my %metainfo = %+;

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

sub selectvector {
    my $self = shift;
    my $blockstring = shift;

    my $compiled = eval 
       'sub {
          local $_ = shift;
          local %_ = %{ $self->metarecord($_) };
          my ($dummy) = $_ =~ /^"(.+)"$|^(.+)$/;
          local @_ = split("~", $dummy); undef $dummy;
          '. $blockstring .'
        }';
    die $@ unless($compiled);

    my @output;
    my ($ms, $me) = (0, 0);
    for my $i (0..$#{ $self->{strings} }) {
	if ($compiled->($self->{strings}->[$i])) {
	    $ms = 1;
	    die "Selection is not contiguous" if $me;
	    push @output, $i;
	} elsif ($ms) {
	    $me = 1;
	}
    }
    return @output;
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
