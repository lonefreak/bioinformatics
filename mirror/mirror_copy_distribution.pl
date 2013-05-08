#! /usr/bin/perl

# MIRROR
# mirror_copy_distribution.pl 0.1
# Author: Fabricio Leotti
# Created at: 06/abr/2013
# Updated at: 23/abr/2013
# Description: Randomly finds and cuts records in a MySQL table to represent the same length distribution as in <distribution file>
# Usage: $ ./mirror_copy_distribution.pl <distribution file> <result fasta file> <database> <table>

use strict;
use DBD::mysql;
use Tie::File;
use Time::HiRes qw(gettimeofday);
use Parallel::Loops;

my ($USAGE) = "\nUSAGE: $0 <distribution file> <result fasta file> <database> <table>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1]) || !defined($ARGV[2]) || !defined($ARGV[3])) {
	die $USAGE;
}

my $table = pop;
my $database = pop;
my $result = pop;
my $copy_from = pop;
print "Starting process (",&current_time,")\n";
&log("Starting process (".&current_time.")\n");
my $connect = &connect($database);
&log("Starting distribution extraction. (".&current_time.")\n");
my ($min, $total, %lengths) = &to_hash($copy_from);
my %seq_hash = &copy_distribution(\%lengths, $table, $min, $total);
#&print_hash_to_file(\%seq_hash, $result);
print "Done distribution copy. (",&current_time,")\n";
&log("Done distribution copy. (".&current_time.")\n");
exit;

sub log {
	open(LOG, ">>/tmp/mirror.log") || die "cannot open label file /tmp/mirror.log\n";
	print LOG $_[0];
	close(LOG);
}

sub print_array {
	my (@array) = @{$_[0]};
	for my $item (@array) {
		print $item, "\n";
	}	
}

sub print_hash_to_file {
	print "Writting output file. (",&current_time,")\n";
	&log("Writting output file. (".&current_time.")\n");
	my (%hash) = %{$_[0]};
	my $output = $_[1];
        open(my $result, ">>$output") || die "cannot open label file $output\n";
	for my $id (keys(%hash)) {
	    	print $result ">modified sequence $id","\n",$hash{$id},"\n";
	}
        close($result);
	print "Finished writting output file. (",&current_time,")\n";
	&log("Finished writting output file. (".&current_time.")\n");
}

sub print_hash {
	my (%hash) = %{$_[0]};
        for my $key (keys(%hash)) {
                print "KEY: ",$key," => VALUE: ",$hash{$key},"\n";
        }
}

sub write_output {
	my ($seq, $output) = @_;
	open(my $result, ">>$output") || die "cannot open label file $output\n";
	print $result ">modified sequence ",&current_time,"\n",$seq,"\n";
	close($result);
}

sub is_defined {
	my %hash = %{$_[0]};

	my $len = $_[1];
	my $min = $_[2];
	if(defined($hash{$len})) { return $len; }
	my $inf = int($len - ( 0.25 * $len));
	for(my $i = $inf; $i <= $len; $i++) {
		if(defined($hash{$i})) { return $i; }
	}
#	for(my $i = 0; $i < 10; $i++) {
#		my $n = int(rand($len-$min)) + $min;
#		if(defined($hash{$n})) { return $n; }
#	}
	return 0;
}

sub copy_distribution {
	my %lengths = %{$_[0]};
	my $table = $_[1], my $initial_length = scalar(keys(%lengths));
	my $min = $_[2];
	my $total = $_[3];
	my %copied_distribution, my %selected_rows, my %seq_ids, my %temp_seqs;

	my $parallel = 0;

	&log("Number of sequences in original distribution: ".$total." (".&current_time.")\n");
	print "Starting copy proccess. (",&current_time,")\n";
	&log("Starting copy proccess. (".&current_time.")\n");

	do {
		%selected_rows = &get_random_elements_bigger_than($table, $min);
	
		if($parallel) {
			my $maxProcs = 4;
			my $parallax = Parallel::Loops->new($maxProcs);
			$parallax->share(\%copied_distribution);
			$parallax->share(\%selected_rows);
			$parallax->share(\%seq_ids);
			my @keys = keys(%selected_rows);
			$parallax->foreach(\@keys, sub {
				my $row = $_;
				unless(defined($seq_ids{$row})) {
	                                if(defined($lengths{length($selected_rows{$row})})) {
	                                        $lengths{length($selected_rows{$row})}--;
	                                        $copied_distribution{$row} = $selected_rows{$row};
						$temp_seqs{$row} = $selected_rows{$row};
	                                        $seq_ids{$row} = 1;
	                                }
	                        }
			}
				
			);
	
		} else {

			my $found = scalar(keys(%copied_distribution));
			foreach my $row (keys(%selected_rows)) {
				
#				unless(defined($seq_ids{$row})) {
					my $len = length($selected_rows{$row});
					my $cut = 0;
					if(($cut = &is_defined(\%lengths, $len)) > 0) {
						$lengths{$cut}--;
						unless($lengths{$cut}) {
							undef($lengths{$cut});
						}
						$copied_distribution{$row} = $temp_seqs{$row} = substr($selected_rows{$row},0,$cut);
						$found++;
#						$seq_ids{$row} = 1;
					}
#				}
				if($found>=$total) { last; }
			}
		}
		&log("Found so far: ".scalar(keys(%copied_distribution))." of $total\n");
		&print_hash_to_file(\%temp_seqs, $result);
		undef(%temp_seqs);
	} while (scalar(keys(%copied_distribution)) < $total);
	print "Copy proccess finished. (",&current_time,")\n";
	&log("Copy proccess finished. (".&current_time.")\n");
	return %copied_distribution;
}

sub get_random_elements_bigger_than {
	my $table = $_[0];
	my $min = $_[1];
	my $limit = 100000;
	my %seq_hash;
	my ($seconds, $microseconds) = gettimeofday;

	my $query = 'SELECT  *
			FROM    (
        		SELECT  @cnt := COUNT(*) + 1,
                		@lim := '.$limit.'
        		FROM    '.$table.'
        		) vars
		STRAIGHT_JOIN
        		(
        		SELECT  d.length, d.seq_id, d.seq,
                		@lim := @lim - 1
        		FROM    '.$table.' d
        		WHERE   (@cnt := @cnt - 1)
				AND d.length >= '.$min.'
        		        AND RAND('.$microseconds.') < @lim / @cnt
        		) i;';

	&log("Querying... (".&current_time.")\n");
	#print "\t",$query, "\n";
	my $q = $connect->prepare($query);
	my $results = $connect->selectall_hashref($query, 'seq_id');
	&log("Query done... ".scalar(keys %$results)." found. (".&current_time.")\n");

	foreach my $id (keys %$results) {
		$seq_hash{$results->{$id}->{seq_id}} = $results->{$id}->{seq};
	}
	return %seq_hash;
}

sub to_array {
	my $filename = $_[0];
	tie my @array, 'Tie::File', $copy_from or die "cannot open label file $copy_from\n";
	return @array;
}

sub to_hash {
        my $filename = $_[0];
        my $handler;
        open($handler, "<$filename") || die "cannot open fasta file $filename\n";
        my %result_hash;
	my $inf = my $total = 0;
        while(<$handler>) {
		chomp;
		$total++;
		if($inf==0) { $inf = $_; }
		if(defined($result_hash{$_})) {
			$result_hash{$_}++;
		} else {
			$result_hash{$_} = 1;
		}
        }
        close($handler);
        return ($inf, $total, %result_hash);
}

sub current_time {
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
 	my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
 	(my $second, my $minute, my $hour, my $dayOfMonth, my $month, my $yearOffset, my $dayOfWeek, my $dayOfYear, my $daylightSavings) = localtime();
 	my $year = 1900 + $yearOffset;

	($second, $minute, $hour, $dayOfMonth) = (&add_trailing_zero($second), &add_trailing_zero($minute), &add_trailing_zero($hour), &add_trailing_zero($dayOfMonth));

	my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
 	return $theTime;
}

sub add_trailing_zero {
	if($_[0] >= 0 && $_[0] <= 9) {
		return "0$_[0]";
	}
	return $_[0];
}

sub connect {
	# CONFIG VARIABLES
	my $host = "localhost";
	my $database = $_[0];
	my $user = "root";
	my $pw = "root";
	my $connect = DBI->connect("DBI:mysql:database=$database;host=$host",$user, $pw, {RaiseError => 1});
	return $connect;
}
