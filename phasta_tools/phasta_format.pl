#!/usr/bin/perl

# Phasta Format 0.1
# Author: Fabricio Leotti
# Description: Convert multiline sequences in single-line sequences in fasta.
# Usage: $ ./phasta_format.pl <fasta_file> <output_fasta_file>

use strict;
use warnings;
use autodie;

open LOG, '>', '/tmp/phasta_format.log' or die $!;
open OUTPUT, '>', $ARGV[1] or die $!;
#my $total_sequences = 0;
#my $found_sequences = 0;
#my $is_sequence = 0;

print "[PHASTA TOOLS] Fasta Formatter Started!! [".localtime()."]\n";
print LOG "[PHASTA TOOLS] Fasta Formatter Started!! [".localtime()."]\n";
my $first_line = 1; 
open my $fasta_file, '<', $ARGV[0];
while(<$fasta_file>) {
	next if /^\s*$/;
	chomp;
	print OUTPUT "\n" if /^>/ && $first_line == 0; 
	print OUTPUT $_;
	print OUTPUT "\n" if /^>/; 
	$first_line = 0;
}

print "[PHASTA TOOLS] Fasta Formatter Finished!! [".localtime()."]\n";
print LOG "[PHASTA TOOLS] Fasta Formatter Finished!! [".localtime()."]\n";
