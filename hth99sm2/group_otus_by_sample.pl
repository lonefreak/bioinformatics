#! /usr/bin/perl

use strict;
use Algorithm::Combinatorics qw(combinations);

my $otu_table = shift;
my $caption_sum = 0;
my $line_sum = 0;
my $total_lines = 0;
my %samples;
my @caption;

foreach my $arg (@ARGV) {
	$samples{$arg} = 1;
}

$total_lines = &process_file ($line_sum, $total_lines, $caption_sum, $otu_table);
&print_hash(\%samples);
print "Total de linhas encontradas: $total_lines\n\n";

sub print_hash {
        my (%hash) = %{$_[0]};
        for my $key (keys(%hash)) {
                print $key,", ",$hash{$key},"\n";
        }
}

sub process_caption {
	@caption = split("\t", $_[0]);
	for(my $i = 1; $i <= $#caption; $i++) {
		if(defined($samples{$caption[$i]})) {
			$samples{$caption[$i]} = 2**$i;
			$caption_sum += 2**$i;
			print "################################";
		}
		print $caption[$i], " => ", $i, "\n";
	}
}

sub process_line {
	my @line = split("\t", $_[0]);
	for(my $i = 1; $i < $#line; $i++) {
		if($line[$i] + 0.0 > 0) {
			#print $caption[$i],"\n";
			#print $line[$i], " + 0.0 = ", ($line[$i] + 0.0), "\n"; 
			$line_sum += 2**$i;
		}
		#print "LINESUM: ",$line_sum,"\n";
	}
}

sub process_file {
	my ($line_sum, $total_lines, $caption_sum, $otu_table) = (shift, shift, shift, shift);

	open( TABLE, "<$otu_table" ) || die "Could not open the file $otu_table\n";
	<TABLE>;
	while (<TABLE>) {
		chomp;
		if ( $_ =~ m/^\#OTU/ ) {
			&process_caption($_);    #proccess caption
			print "Procurando por somas iguais a $caption_sum\n\n";
			print $_, "\n";
		}
		elsif ( $_ =~ m/^\#/ ) {
			next;                    #discard this line
		}
		else {
			&process_line($_);
			if ( $caption_sum == $line_sum ) {

				#print $_, "\n";
				$total_lines++;
			}
			$line_sum = 0;
		}
	}
	close(TABLE);
	return $total_lines;
}
