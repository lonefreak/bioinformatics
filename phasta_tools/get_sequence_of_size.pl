#!/usr/bin/perl -w

#                                                        
#  PROGRAM: get_seqeunce_of_size.pl                                     30.Mai.2013     
#
#  DESCRIPTION: Returns the first occurrence of a sequence with exactly the informed size in a fasta file, or the larger sequence, if none informed  
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 30.Mai.2013
#  
use strict;
use warnings;

my ($USAGE) = "\nUSAGE: $0 <input fasta file> [<length of sequence>]\n";
my $target_length = 0;

if (!defined($ARGV[0])) {
        die $USAGE;
}

if (defined($ARGV[1])) {
        $target_length = $ARGV[1] + 0.0;
}

my $file = $ARGV[0];
my $nbr_sequences = my $seq_length = my $average_length = my $total_seq_length = my $max_length = my $min_length = 0;
my $seq = my $max_seq = my $label = my $max_label = '';
my $newline;
open(FILE, "<$file") || die "cannot open $file\n";
open(OUT, ">seqofsize.output.fasta") || die "cannot create output file\n";
while(<FILE>){
	chomp;
	if($_ =~ m/^>/) {
		$label = $_;
		my $position = tell();
		while($newline = <FILE>) {
			chomp($newline);
			if ($newline =~ m/^>/) { last; }
			$seq = $seq . $newline;
		}
		seek(FILE, $position, 0);
		$seq_length = length($seq);
		if($target_length && $target_length == $seq_length) {
			print "Found first sequence with length $target_length\n";
			print OUT $label."\n".$seq."\n";
			exit;
		}
		if($seq_length > $max_length) { 
			$max_length = $seq_length; 
			$max_seq = $seq;
			$max_label = $label;
		}
		$seq = '';
	}
}
close(FILE);
if($target_length) {
	print "No sequence with informed length was found!\n";
} else {
	print "Found max size sequence of length $max_length\n";
	print OUT $max_label,"\n",$max_seq,"\n";
}
