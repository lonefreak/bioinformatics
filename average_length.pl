#!/usr/bin/perl -w

#                                                        
#  PROGRAM: average_length.pl                                     24.Oct.2012     
#
#  DESCRIPTION: Calculates the average, N50, maximum and minimum size of sequences in a fasta file       
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 04.Jun.2013
#  
use strict;
use warnings;

my ($USAGE) = "\nUSAGE: $0 <output fasta file>\n";

if (!defined($ARGV[0])) {
        die $USAGE;
}

my $file = $ARGV[0];
my $nbr_sequences = my $seq_length = my $average_length = my $total_seq_length = my $max_length = my $min_length = 0;
my @n50values;
open(FILE, "<$file") || die "cannot open $file\n";
while(<FILE>){
	chomp;
	if($_ =~ m/^>/) {
		$total_seq_length += $seq_length;
		if($seq_length > $max_length) { $max_length = $seq_length; }
		if($seq_length < $min_length || $min_length == 0) { $min_length = $seq_length; }
		if($seq_length) {
			push(@n50values, $seq_length);
		}
		$seq_length = 0; 
		$nbr_sequences++;
	} else {
		$seq_length += length($_);
	}
}
push(@n50values, $seq_length);
$total_seq_length += $seq_length;
if($seq_length > $max_length) { $max_length = $seq_length; }
if($seq_length < $min_length || $min_length == 0) { $min_length = $seq_length; }
$seq_length = 0;

close(FILE);
$average_length = $total_seq_length / $nbr_sequences;
print "Total number of sequences: $nbr_sequences\n";
print "Total length: $total_seq_length\n";
print "Average:\t$average_length\n";
print "Max:\t$max_length\n";
print "Min:\t$min_length\n";
my $n50 = &n50($total_seq_length, \@n50values);
print "N50:\t$n50\n\n";

sub n50 {
	my @arr = @{$_[1]};
	my $total_length = $_[0];
	@arr = reverse sort {$a <=> $b} @arr;
	my $n50 = $arr[0];
	my $covered = $total_length;
	while ($covered > $total_length/2) {
	        $n50 = shift(@arr);
	        $covered -= $n50;
	}
	return $n50;
}
