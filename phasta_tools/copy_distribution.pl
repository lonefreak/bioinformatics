#! /usr/bin/perl

# copy_distribution.pl 0.1
# Author: Fabricio Leotti
# Created at: 06/abr/2013
# Updated at: 06/abr/2013
# Description: Extract a random subset of sequences from <copy_to fasta file> and randomly cuts them to represent the same length distribution as in <copy_from fasta file>
# Usage: $ ./copy_distribution.pl <copy_from fasta file> <copy_to fasta file> <result fasta file>

use strict;
use MongoDB;
use MongoDB::OID;

my ($USAGE) = "\nUSAGE: $0 <copy_to fasta file> [<copy_to fasta file> [<copy_to fasta file> [...]]] <copy_from fasta file> <result fasta file>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1]) || !defined($ARGV[2])) {
	die $USAGE;
}

my $result = pop;
my $copy_from = pop;
my @samples = ();
my $total_samples = @ARGV;
my $len = 0;
print "Starting process (",&current_time,")\n";

my $DATABASE = "distribution";
my $COLLECTION = "dmel";
my $conn = MongoDB::Connection->new;
my $db = $conn->$DATABASE;
my $dmel = $db->$COLLECTION;

$dmel->drop();

while(@ARGV>0) {
	$len = @ARGV;
	print "Including sample file ",$total_samples-$len+1," of ",$total_samples," (",&current_time,")\n";
	&add_to_collection($dmel, shift);
	print "Creating index (",&current_time,")\n";
	$dmel->ensure_index({'length' => 1});
}

$len = $dmel->count();
print "Total samples included: ", $len," (",&current_time,")\n";

print "####################################################\n";
print "Starting distribution extraction. (",&current_time,")\n";
(my $q, my %distribution) = &extract_lengths($copy_from);
print "Number of sequences in original distribution: ", $q, " (",&current_time,")\n";
print "Distribution:\n";
&print_hash(\%distribution);

print "####################################################\n";
print "Starting distribution copy. (",&current_time,")\n";
my %copied_distribution = &copy_distribution(\%distribution, $dmel, $result);
print "\n\nCopied Distribution:\n";
&print_hash(\%copied_distribution);
print "####################################################\n";
print "Done distribution copy. (",&current_time,")\n";


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
	my ($seq, $index, $output) = @_;
	open(my $result, ">>$output") || die "cannot open label file $output\n";
    print $result ">modified sequence ",$index,"\n",$seq,"\n";
	close($result);
}

sub copy_distribution {
	my %hash = %{$_[0]};
	my @array = ();
	my $coll = $_[1];
	my $output = $_[2];
	my $element = "";
	my %copied_distribution;
	my @lengths = ();
	my $index = -1;
	foreach my $length (keys(%hash)) {
		@array = &build_sequence_array($length,$dmel);
		print "Looking for $hash{$length} elements with length of $length. (",&current_time,")\n";
		for(my $i=0; $i < $hash{$length}; $i++) {
			print "\tElement ", $i+1 ,". (",&current_time,")\n";
			($element, $index, @array) = &get_random_element_of_length($length, \@array);
			if($element) {
				&write_output($element, $index, $output);
				push(@lengths, $element);
				print "\tElement found. (",&current_time,")\n";
			} else {
				print "\tElement not found. (",&current_time,")\n";
			}
		}
	}
	%copied_distribution = &add_lengths(\@lengths);
	return %copied_distribution;
}

sub build_sequence_array {
	my $min_length = $_[0] + 0.0;
	my $coll = $_[1];
	my @sequence_array = ();

	my $seqs = $db->get_collection( 'dmel' )->find({'length' => {'$gte'=> $min_length}});
	my @a = $seqs->all;
	foreach my $seq (@a) {
		my %s = %{$seq};
		push(@sequence_array,$s{'seq'});
		#print $s{'seq'}, "\n";
	}
	return @sequence_array;	
}

sub get_random_element_of_length {
	my $length = $_[0];
	my @array = @{$_[1]};
	my $element = "";
	my $index = -1;
	do {
		($element, $index, @array) = &get_random_element(\@array);
		if(length($element) >= $length) {
			$element = substr($element, 0, $length);
		}
		print "\t\t. ", length($element), " (",&current_time,")\n";
	} while(length($element) < $length && @array > 0);
	if(@array == 0) { die "Unable to copy the distribution!!"; }
	return ($element, $index, @array);
}

sub get_random_element {
	my @array = @{$_[0]};
	my $index = int(rand(@array));
	my $element = splice(@array,$index,1);
	return ($element, $index, @array);
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
				die "A problem has occured during the processing of the FASTA file $filename";
			}
		}
	}
	close($handler);
	return @result_array;
}

sub add_to_collection {
	my $collection = $_[0];
	my $filename = $_[1];

	my $handler;
        open($handler, "<$filename") || die "cannot open fasta file $filename\n";
        while(<$handler>) {
		chomp;
                if($_ =~ m/^>/) {
			my $label = $_;
                        my $position = tell();
                        my $newline = <$handler>;
                        my $current_seq = "";
                        while($newline =~ m/^[^>]/) {
                                chomp($newline);
                                $current_seq .= $newline;
                                $newline = <$handler>;
                        }
			$collection->insert({	"label"	=>	$label,
						"seq"	=>	$current_seq,
						"length"=>	length($current_seq)});
                        unless(seek($handler,$position,0)) {
                                die "A problem has occured during the processing of the FASTA file $filename";
                        }
                }
        }
        close($handler);
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
