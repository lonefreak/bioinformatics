#! /usr/bin/perl

# MIRROR
# generate_distribution_file.pl 0.1
# Author: Fabricio Leotti
# Created at: 24/abr/2013
# Updated at: 24/abr/2013
# Description: Generate a text file containing the numerically ordered lenghts of sequences in at least one fasta file.
# Usage: $ ./mirror_generate_distribution_file.pl <fasta file> [<fasta file> [<fasta file> [...]]] <output file> <min length> <max length>
# Output: <output file>

use strict;

my ($USAGE) = "\nUSAGE: $0 <fasta file> [<fasta file> [<fasta file> [...]]] <output file> <min length> <max length>";

if (@ARGV < 4) {
	die $USAGE;
}

my $max_length = pop;
my $min_length = pop;
my $output = pop;
my @lengths;
my $total_samples = @ARGV;
my $smaller = my $bigger = my $_smaller = my $_bigger = my $len = my $tmp_len = my $total_seqs = my $discarded = my $tmp_discarded = 0;
print "Starting process (",&current_time,")\n";
open(my $handler, ">$output") || die "cannot open fasta file $output\n";
while(@ARGV>0) {
	$len = @ARGV;
	print "Analyzing file ",$total_samples-$len+1," of ",$total_samples," (",&current_time,")\n";
	($tmp_len,$tmp_discarded,$_smaller,$_bigger,@lengths) = &add_to_file($handler, shift, $min_length, $max_length,\@lengths);
	$total_seqs += $tmp_len;
	$discarded += $tmp_discarded;
	if($_smaller<$smaller || $smaller == 0) {$smaller = $_smaller;}
	if($_bigger>$bigger) {$bigger = $_bigger;}
	print "\t$tmp_len sequences included, $tmp_discarded discarted (",&current_time,")\n";
}

print "Sorting results (",&current_time,")\n";
@lengths = sort {$a <=> $b} @lengths;
my $included_smaller = $lengths[0];
my $included_bigger = $lengths[$#lengths];
&print_array_to_file(\@lengths,$output);
close($handler);

print "Total sequences analyzed:\t", $total_seqs+$discarded,"\n";
print "\tSmallest sequence:\t", $smaller," pb\n";
print "\tBiggest sequence:\t", $bigger," pb\n";
print "Total sequences included:\t", $total_seqs," (", ($total_seqs/($total_seqs+$discarded))*100 ,"%)\n";
print "\tSmallest sequence:\t", $included_smaller," pb\n";
print "\tBiggest sequence:\t", $included_bigger," pb\n";
print "Total sequences discarded:\t", $discarded," (", ($discarded/($total_seqs+$discarded))*100 ,"%) (",&current_time,")\n";
exit;

sub print_array_to_file {
        print "Writting output file. (",&current_time,")\n";
        my (@array) = @{$_[0]};
        my $output = $_[1];
        open(my $result, ">$output") || die "cannot open label file $output\n";
        for my $len (@array) {
                print $result $len,"\n";
        }
        close($result);
        print "Finished writting output file. (",&current_time,")\n";
}

sub add_to_file {
	my $out = $_[0];
	my $filename = $_[1];
	my $min_length = $_[2] + 0.0;
	my $max_length = $_[3] + 0.0;
	my @lengths = @{$_[4]};
	my $total_seqs = my $discarded = my $smaller = my $bigger = 0;

        open(my $handler, "<$filename") || die "cannot open fasta file $filename\n";
        while(<$handler>) {
		chomp;
                if($_ =~ m/^>/) {
                        my $position = tell();
                        my $newline = <$handler>;
                        my $current_seq = "";
                        while($newline =~ m/^[^>]/) {
                                chomp($newline);
                                $current_seq .= $newline;
                                $newline = <$handler>;
                        }
			my $seq_len = length($current_seq);
			if($seq_len<$smaller || $smaller == 0) {$smaller = $seq_len;}
			if($seq_len>$bigger) {$bigger = $seq_len;}
			if(
			($seq_len >= $min_length || $min_length == 0) && 
			($seq_len <= $max_length || $max_length == 0)) {
				push(@lengths,$seq_len);
				$total_seqs++;
			} else {
				$discarded++;
			}
                        unless(seek($handler,$position,0)) {
                                die "A problem has occured during the processing of the FASTA file $filename";
                        }
                }
        }
        close($handler);
	return ($total_seqs,$discarded,$smaller,$bigger,@lengths);
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
