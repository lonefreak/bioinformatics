#! /usr/bin/perl

# copy_distribution.pl 0.1
# Author: Fabricio Leotti
# Created at: 06/abr/2013
# Updated at: 06/abr/2013
# Description: Extract a random subset of sequences from <copy_to fasta file> and randomly cuts them to represent the same length distribution as in <copy_from fasta file>
# Usage: $ ./copy_distribution.pl <copy_from fasta file> <copy_to fasta file> <result fasta file>

use strict;

my ($USAGE) = "\nUSAGE: $0 <copy_from fasta file> <copy_to fasta file> <result fasta file>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1]) || !defined($ARGV[2])) {
	die $USAGE;
}

my $copy_from = $ARGV[0];
my $copy_to = $ARGV[1];
my $result = $ARGV[2];

(my $q, my %distribution) = &extract_lengths($copy_from);
print "Number of sequences: ", $q, "\n\n";
print "Distribution:\n";
&print_hash(\%distribution);

my @samples = &to_array($copy_to);
my %copied_distribution = &copy_distribution(\%distribution, \@samples, $result);
print "\n\nCopied Distribution:\n";
&print_hash(\%copied_distribution);


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

sub write_output {
	my ($seq, $output) = @_;
	open(my $result, ">>$output") || die "cannot open label file $output\n";
    print $result ">",length($seq),"\n",$seq,"\n";
	close($result);
}

sub copy_distribution {
	my %hash = %{$_[0]};
	my @array = @{$_[1]};
	my $output = $_[2];
	my $element = "";
	my %copied_distribution;
	my @lengths = ();
	foreach my $length (keys(%hash)) {
		for(my $i=0; $i < $hash{$length}; $i++) {
			($element, @array) = &get_random_element_of_length($length, \@array);
			if($element) {
				&write_output($element, $output);
				push(@lengths, $element);
			}
		}
	}
	%copied_distribution = &add_lengths(\@lengths);
	return %copied_distribution;
}

sub get_random_element_of_length {
	my $length = $_[0];
	my @array = @{$_[1]};
	my $element = "";
	do {
		($element, @array) = &get_random_element(\@array);
		if(length($element) >= $length) {
			$element = substr($element, 0, $length);
		}
	} while(length($element) < $length && @array > 0);
	if(@array == 0) { die "Unable to copy the distribution!!"; }
	return ($element, @array);
}

sub get_random_element {
	my @array = @{$_[0]};
	my $element = splice(@array,rand(@array),1);
	return ($element, @array);
}

sub to_array {
	my $filename = $_[0];
	my $handler;
	open($handler, "<$filename") || die "cannot open fasta file $filename\n";
	my @result_array = ();
	while(<$handler>) {
		if($_ =~ m/^>/) {
			my $position = tell();
			my $newline = <$handler>;
			my $current_seq = "";
			while($newline =~ m/^[^>]/) {
				chomp($newline);
				$current_seq .= $newline;
				$newline = <$handler>;
			}
			push(@result_array, $current_seq);
			unless(seek($handler,$position,0)) {
				die "A problem has occured during the processing of the FASTA file.";
			}
		}
	}
	close($handler);
	return @result_array;
}

sub extract_lengths {
	my @lengths;
	my $fasta = $_[0];
	my @seqs = &to_array($fasta);
	my $q = @seqs;
	my %distribution = &add_lengths(\@seqs);
	return ($q, %distribution);
}

sub add_lengths {
	my @seqs = @{$_[0]};
	my %distribution;
	my $len = 0;
	foreach my $seq (@seqs) {
		$len = length($seq);
		if(defined($distribution{$len})) {
			$distribution{$len}++;
		} else {
			$distribution{$len} = 1;
		}
	}
	return %distribution;
}