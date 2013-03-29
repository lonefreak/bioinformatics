#! /usr/bin/perl

use strict;

my $caption_sum = 0;
my $line_sum = 0;
my $total_lines = 0;
my $table, my $output;
my %target_sums;
my @caption;

my $otu_table = shift;
my $output_file = shift;
my $permanent_sample = shift;
my @combinatory_samples = @ARGV;

open($table , "<", $otu_table ) || die "Could not open the file $otu_table\n";
open($output , ">", $output_file ) || die "Could not open the file $output_file\n";

print get_caption($table), "\n";
print $output get_caption($table), "\n";
%target_sums = &set_samples_combination($table, $permanent_sample, \@combinatory_samples);
$total_lines = &process_file($table, $output, \%target_sums);
print "Total de linhas encontradas: $total_lines\n\n";
close($table);

sub print_hash {
        my (%hash) = %{$_[0]};
        for my $key (keys(%hash)) {
                print $key," => ",$hash{$key},"\n";
        }
}

sub set_samples_combination {
	#receives: file handler, permanent sample, combinatory sample
	#returns: hash containing target binary sum for each sample combination
	my %target_sums, my %samples;
	my $target_sum = 0;
	my $caption = "";
	my ($table, $permanent_sample, $combinatory_samples) = @_;
	
	$caption = get_caption ($table);
	if ($caption eq "") { die "Error trying to read the OTU Table caption."; }
	
	if(!@{$combinatory_samples}) {
		%samples = &scalar_to_hash_with_default_value(join(" ", $permanent_sample), " ", 1);
		$target_sum = &process_sample($caption, \%samples);
		$target_sums{$target_sum} = 1;
	} else {
		my @combinations = &get_combinations(@{$combinatory_samples});
		for my $combination (@combinations) {
			%samples = &scalar_to_hash_with_default_value(join(" ", $permanent_sample, @{$combination}), " ", 1);
			$target_sum = &process_sample($caption, \%samples);
			$target_sums{$target_sum} = 1;
		}
	}
	
#	print "################################\n";
#	&print_hash(\%target_sums);
#	print "################################\n";
#	exit;
	return %target_sums;
}

sub scalar_to_hash_with_default_value {
	my ($string, $separator, $default) = @_;
	my @elements = split($separator, $string);
	my %hash;
	for my $item (@elements) {
		$hash{$item} = $default;
	}
	return %hash;
}

sub get_combinations {
	use Algorithm::Combinatorics qw(combinations);
	my @combinatory_samples = @_;
	my @combinations;
	for(my $i = 1; $i <= $#_ + 1; $i++) {
		push(@combinations, combinations(\@_, $i));
	}
	return @combinations;
}

sub process_sample {
	my($caption, $s) = @_;
	my %samples = %{$s};
#	&print_hash(\%samples);
	my @capt = split("\t", $caption);
#	print "=====================\n";
#	print @capt, "\n";
# 	print "=====================\n";
	my $target_sum = 0;
	for(my $i = 1; $i <= $#capt; $i++) {
		if(defined($samples{$capt[$i]})) {
#			print "********************\n";
#			print $capt[$i], " -> ", $i, " -> ", 2**$i, "\n";
#			print "********************\n";
			$target_sum += 2**$i;
		}
	}
	return $target_sum;
}

sub process_line {
	my @line = split("\t", $_[0]);
	my %target_sums = %{$_[1]};
	for(my $i = 1; $i <= $#line; $i++) {
		if($line[$i] + 0.0 > 0) {
			$line_sum += 2**$i;
		}
	}
	if(defined($target_sums{$line_sum})) {
		return $_[0];
	} else {
		return "";
	}
}

sub process_file {
	my ($table, $output_file, $target) = @_;
	my %target_sums = %{$target};
	my $processed_line;
	seek($table,0,0);
	while (<$table>) {
		chomp;
		if ( $_ =~ m/^\#/ ) {
			next;
		}
		$processed_line = &process_line($_, \%target_sums);
		if ( $processed_line ) {
			print $processed_line, "\n";
			print $output_file $processed_line, "\n";
			$total_lines++;
		}
		$line_sum = 0;
	}
	return $total_lines;
}

sub get_caption {
	my ($table) = @_;
	my $caption = "";
	seek($table,0,0);
	while (<$table>) {
		chomp;
		if ( $_ =~ m/^\#OTU/ ) {
			$caption = $_;
			last;
		}
	}
	return $caption;
}
