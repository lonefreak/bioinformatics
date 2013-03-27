#! /usr/bin/perl

# length_distribution.pl 0.1
# Author: Fabricio Leotti
# Created at: 20/mar/2013
# Updated at: 20/mar/2013
# Description: Generates a distribuition file of the lengths of the sequences in a FASTA file
# Usage: $ ./length_distribution.pl <input fasta file> <output distribution file>
# Input: <input fasta file> FASTA file
# Return: <output distribution file> created on the folder specified in the second parameter

use strict;

my ($USAGE) = "\nUSAGE: $0 <input fasta file> <output distribution file>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1])) {
	die $USAGE;
}

my $fasta = $ARGV[0];
my $dist = $ARGV[1];

if (substr($fasta, -5, 5) ne "fasta" && substr($fasta, -3, 3) ne "fna") {
	die "You need to privide a .fasta or .fna file as input\n$USAGE";
}

my %distribution;
my $q = 0;
&extract_lengths();
print "Number of sequences: ", $q, "\n\n";
&write_output(\%distribution);
print "Distribution:\n";
&print_hash(\%distribution);

#sub write_labels {
#        open(FASTA, "<$fasta") || die "cannot open fasta file $fasta\n";
#	open(LABEL, ">$label") || die "cannot open label file $label\n";
#        while(<FASTA>) {
#		my $position = tell();
#                if($_ =~ m/^>/) {
#			chomp;
#			$_ =~ s/^>//; 
#			print LABEL "$_\n";
#                }
#        }
#	close(FASTA);
#        close(LABEL);
#        print "Done!\n\n";
#}

sub write_output {
	open(DIST, ">$dist") || die "cannot open label file $dist\n";
	my (%hash) = %{$_[0]};
        for my $key (keys(%hash)) {
                print DIST $key,",",$distribution{$key},"\n";
        }
	close(DIST);
}

sub print_array {
	my (@array) = @{$_[0]};
	for my $item (@array) {
		print $item, "\n";
	}	
}

sub print_hash {
	my (%hash) = %{$_[0]};
        for my $key (keys(%hash)) {
                print $key,", ",$distribution{$key},"\n";
        }
}

sub extract_lengths {
	my @lengths;
	open(FASTA, "<$fasta") || die "cannot open fasta file $fasta\n";
	while(<FASTA>) {
		if($_ =~ m/^>/) {
			$q++;
			my $position = tell();
			my $newline = <FASTA>;
			my $current_seq = "";
			while($newline =~ m/^[^>]/) {
				chomp($newline);
				$current_seq .= $newline;
				$newline = <FASTA>;
			}
			&add_length(length($current_seq));
			unless(seek(FASTA,$position,0)) {
				die "A problem has occured during the processing of the FASTA file.";
			}	
		}
	}
	close(FASTA);
}

sub add_length {
	if(defined($distribution{$_[0]})) {
		$distribution{$_[0]}++;
	} else {
		$distribution{$_[0]} = 1;
	}
}
