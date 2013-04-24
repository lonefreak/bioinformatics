#! /usr/bin/perl

# MIRROR
# mirror_copy_distribution.pl 0.1
# Author: Fabricio Leotti
# Created at: 06/abr/2013
# Updated at: 23/abr/2013
# Description: Randomly finds and cuts records in a MySQL table to represent the same length distribution as in <copy_from fasta file>
# Usage: $ ./mirror_copy_distribution.pl <copy_from fasta file> <result fasta file> <database> <table>

use strict;
use List::Util qw( min max );
use DBD::mysql;

my ($USAGE) = "\nUSAGE: $0 <copy_from fasta file> <result fasta file> <database> <table>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1]) || !defined($ARGV[2]) || !defined($ARGV[3])) {
	die $USAGE;
}

my $table = pop;
my $database = pop;
my $result = pop;
my $copy_from = pop;
print "Starting process (",&current_time,")\n";
my $connect = &connect($database);
print "Starting distribution extraction. (",&current_time,")\n";
my @lengths = &to_array($copy_from);
my @seq_array = &copy_distribution(\@lengths, $table);
&print_array_to_file(\@seq_array, $result);
print "Done distribution copy. (",&current_time,")\n";
exit;

sub print_array {
	my (@array) = @{$_[0]};
	for my $item (@array) {
		print $item, "\n";
	}	
}

sub print_array_to_file {
	print "Writting output file. (",&current_time,")\n";
	my (@array) = @{$_[0]};
	my $output = $_[1];
        open(my $result, ">>$output") || die "cannot open label file $output\n";
	for my $seq (@array) {
	    	print $result ">modified sequence ",&current_time,"\n",$seq,"\n";
	}
        close($result);
	print "Finished writting output file. (",&current_time,")\n";
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

sub copy_distribution {
	my @lengths = @{$_[0]};
	my @array;
	my $coll = $_[1];
	my %copied_distribution;
	my @seqs;


	my $q = @lengths;
	my $min = min @lengths;
	my $max = max @lengths;
	print "Number of sequences in original distribution: ", $q, " (",&current_time,")\n";
	print "Small2er sequence: ", $min, "pb (",&current_time,")\n";
	print "Bigger sequence: ", $max, "pb (",&current_time,")\n";
	print "Starting copy proccess. (",&current_time,")\n";

	my @elements = &get_random_elements_bigger_than($coll, \@lengths, $min);
	for my $element (@elements) {
		push(@seqs, $element);
		#print "\t",length($element)," (",&current_time,")\n";
	}
	print "Copy proccess finished. (",&current_time,")\n";
	return @seqs;
}

sub get_random_elements_bigger_than {
	my $coll = $_[0];
	my @lengths = @{$_[1]};
	my $t = @lengths;
	@lengths = sort {$a <=> $b} @lengths;
	my $min = $_[2];
	my $element = "";
	my @elements;
	my $index = 0;
	my $limit = 15000;

	if($t < 15000) {
		$limit = $t;
	}

	my $query = "select * from $coll where length >= $min order by RAND() limit $limit";

	my $q = $connect->prepare($query);
	my $results = $connect->selectall_hashref($query, 'seq_id');
	foreach my $id (keys %$results) {
		my $l = pop(@lengths);
		$element = $results->{$id}->{seq};
		if(length($element) >= $l) {
                        $element = substr($element, 0, $l);
			$index = 0;
                } else {
			push(@lengths, $l);
			$index++;
		}
		$t = @lengths;
		push(@elements,$element);
		if($index == $t) {
			last;
		}
	}
	return @elements;
}

sub get_random_element_of_length {
	my $length = $_[0];
	my $coll = $_[1];
	my $how_many = $_[2];
	my $element = "";
	my @elements;
	my $index = 0;
	my $query = "select * from $coll where length >= $length order by RAND()";

	my $q = $connect->prepare($query);
	my $results = $connect->selectall_hashref($query, 'seq_id');
	foreach my $id (keys %$results) {
		$index++;
		$element = $results->{$id}->{seq};
		if(length($element) > $length) {
                        $element = substr($element, 0, $length);
                }
		push(@elements,$element);
		if($index == $how_many) {
			last;
		}
	}
	return @elements;
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
			push(@result_array, length($current_seq));
			unless(seek($handler,$position,0)) {
				die "A problem has occured during the processing of the FASTA file $filename";
			}
		}
	}
	close($handler);
	return @result_array;
}

#sub extract_lengths {
#	my @lengths;
#	my $fasta = $_[0];
#	my @seqs = &to_array($fasta);
#	my $q = @seqs;
#	my @distribution = &add_lengths(\@seqs);
#	return ($q, %distribution);
#}

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
	my $pw = "";
	my $connect = DBI->connect("DBI:mysql:database=$database;host=$host",$user, $pw, {RaiseError => 1});
	return $connect;
}
