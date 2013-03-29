#! /usr/bin/perl

use strict;

my $caption_sum = 0;
my $line_sum = 0;
my $total_lines = 0;
my $table;
my %target_sums;
my @caption;

my $otu_table = shift;
my $output_file = shift;
my $permanent_sample = shift;
my @combinatory_samples = @ARGV;

open($table , "<$otu_table" ) || die "Could not open the file $otu_table\n";

%target_sums = &set_samples_combination($table, $permanent_sample, \@combinatory_samples);
$total_lines = &process_file($table, $output_file, \%target_sums);
print "Total de linhas encontradas: $total_lines\n\n";
close($table);

sub print_hash {
        my (%hash) = %{$_[0]};
        for my $key (keys(%hash)) {
                print $key,", ",$hash{$key},"\n";
        }
}

sub set_samples_combination {
	#receives: file handler, permanent sample, combinatory sample
	#returns: hash containing target binary sum for each sample combination
	
	my ($table, $permanent_sample, @combinatory_samples) = (shift, shift, shift);
	my @combinations = &get_combinations(\@combinatory_samples);
	for my $combination (@combinations) {
		print join(" ", $combination, $permanent_sample), "\n";	
	}
	exit;
}

sub get_combinations {
	use Algorithm::Combinatorics qw(combinations);
	my @combinatory_samples = shift;
	return combinations(\@combinatory_samples);	
}

sub process_sample {
	my($caption, %samples) = (shift, shift);
	my @capt = split("\t", $caption);
	my $target_sum = 0;
	for(my $i = 1; $i <= $#capt; $i++) {
		if(defined($samples{$capt[$i]})) {
			$target_sum = 2**$i;
		}
	}
	return $target_sum;
}

sub process_line {
	my @line = split("\t", $_[0]);
	for(my $i = 1; $i < $#line; $i++) {
		if($line[$i] + 0.0 > 0) {
			$line_sum += 2**$i;
		}
	}
}

sub process_file {
	my ($table, $output_file, %target_sums) = (shift, shift, shift);
	my $processed_line;
	while (<$table>) {
		chomp;
		if ( $_ =~ m/^\#/ ) {
			next;
		}
		else {
			$processed_line = &process_line($_);
			if ( $processed_line ) {
				print $output_file $processed_line, "\n";
				$total_lines++;
			}
			$line_sum = 0;
		}
	}
	return $total_lines;
}
