#!/usr/bin/perl

# get_sequences_from_labels 1.0
# Author: Fabricio Leotti
# Description: Get all the sequences in a fasta file that match labels in a label file.
# Usage: $ ./get_sequences_from_labels.pl <labels_file> <fasta_file>
# Return: 'output-lookup.fasta' created on the software folder and '/tmp/output.fasta-lookup.log' containing log information

use strict;
use warnings;
use autodie;

open LOG, '>', '/tmp/output.fasta-lookup.log' or die $!;
open OUT, '>', 'output-lookup.fasta' or die $!;
my $total_sequences = 0;
my $found_sequences = 0;
my $is_sequence = 0;

print "Label Searcher Started!! [".localtime()."]\n";
print LOG "Label Searcher Started!! [".localtime()."]\n";

open my $lookup, '<', $ARGV[0];
my %lookup;
#generate an array from the label files
print "Generating label hash.\n";
print LOG "Generating label hash.\n";
while(<$lookup>) {
	next if /^\s*$/;
	chomp;
	$_ = trim($_);
	$lookup{$_} = 1;
}
close $lookup;

open my $bigfile, '<', $ARGV[1];
print "Searching labels...\n";
print LOG "Searching labels...\n";
while(my $row = <$bigfile>) {
	chomp($row);
	if($row =~ m/^>/) {
		$total_sequences++;
		my $search = $row;
		$search =~ s/(^>)//gi;

		if(defined($lookup{$search})) {
			$found_sequences++;
			$is_sequence = 1;
			print OUT "$row\n";
		}
		if($total_sequences%100000==0) {
			print LOG "$total_sequences sequences scanned so far.\n";
		}
	} else {
		if($is_sequence) {
			print OUT "$row\n";
			$is_sequence = 0;
		}
	}
}
close $bigfile;

print LOG "Total sequences:\t$total_sequences\nSequences found:\t$found_sequences\n";
print "Label Searcher Finished!! [".localtime()."]\n";
print LOG "Label Searcher Finished!! [".localtime()."]\n";

sub trim{
 	my $string = $_;
 	$string =~ s/\s*$//;
 	$string =~ s/^\s*//;
 	return $string;
}
