#! /usr/bin/perl

use strict;

my $otu_table = shift;
my %samples;

foreach my $arg (@ARGV) {
	$samples{$arg} = 1;
}
&print_hash(\%samples);

open(TABLE,"<$otu_table") || die "Could not open the file $otu_table\n";
<TABLE>;
while(<TABLE>) {
	chomp;
	#print "$_\n";
	if($_ =~ m/^\#OTU/) {
		&process_caption($_); #proccess caption
	} elsif($_ =~ m/^\#/) {
		#discard this line
	} else{
		#process line according to args
	}
}

&print_hash(\%samples);

sub print_hash {
        my (%hash) = %{$_[0]};
        for my $key (keys(%hash)) {
                print $key,", ",$hash{$key},"\n";
        }
}

sub process_caption {
	my @caption = split("\t", $_[0]);
	for(my $i = 1; $i < $#caption; $i++) {
		if(defined($samples{$caption[$i]})) {
			$samples{$caption[$i]} = 2**$i;
		}
	}
}
