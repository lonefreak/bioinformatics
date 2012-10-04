#!/usr/bin/perl

use strict;
use warnings;
use autodie;

my ($USAGE) = "\nUSAGE: $0 <haystack> <needles> <output> [reverse]\n";

if (!defined($ARGV[0]) || !defined($ARGV[1]) || !defined($ARGV[2])) {
	die $USAGE;
}

open LOG, '>', '/tmp/search_haystack.log' or die $!;
open OUT, '>', $ARGV[2] or die $!;
my $total_needles = 0;
my $found_needles = 0;
my $reverse = 0;
if($ARGV[3] eq "reverse") {
	$reverse = 1;
}

print "Searcher Started!! [".localtime()."]\n";
print LOG "Searcher Started!! [".localtime()."]\n";

open my $haystack, '<', $ARGV[0];
my %haystack;
#generate an array from the label files
print "Generating label hash.\n";
print LOG "Generating label hash.\n";
while(<$haystack>) {
	next if /^\s*$/;
	chomp;
	$haystack{$_} = 1;
}
close $haystack;

open my $needles, '<', $ARGV[1];
print "Searching needles...\n";
print LOG "Searching needles...\n";
while(my $row = <$needles>) {
	chomp($row);
	$total_needles++;
	my $search = $row;
	$search =~ s/(^>)//gi;
	if(!$reverse && defined ($haystack{$search})) {
		$found_needles++;
		#print "$row\n";
		print OUT "$row\n";
	} elsif ($reverse && !defined ($haystack{$search})) {
                $found_needles++;
                #print "$row\n";
                print OUT "$row\n";
	}
	if($total_needles%100000==0) {
		print LOG "$total_needles needles scanned so far.\n";
	}
}
close $needles;

print LOG "Total needles:\t$total_needles\nNeedles found:\t$found_needles\n";
print "Searcher Finished!! [".localtime()."]\n";
print LOG "Searcher Finished!! [".localtime()."]\n";
