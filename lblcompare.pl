#!/usr/bin/perl -w

use strict;
use warnings;

open(FILE1, "<$ARGV[0]") || die "Cannot read file $ARGV[0]";
open(FILE2, "<$ARGV[1]") || die "Cannot read file $ARGV[1]";

my @arr1, my @arr2;

print "Loading first file...\n";
while(<FILE1>){
	chomp;
	push(@arr1, lc($_));
}
close(FILE1);
print "Loading second file...\n";
while(<FILE2>){
	chomp;
	push(@arr2, lc($_));
}
close(FILE2);
my $len1 = @arr1;
my $len2 = @arr2;
my $longer_array_length = 0;

if(my $longer = $len1<=>$len2) {
	if($longer == 1) {
		$longer_array_length = $len1;
	} elsif($longer == -1) {
		$longer_array_length = $len2;
	}
} else {
	$longer_array_length = $len1;
}

for(my $i = 0; $i < $longer_array_length; $i++) {
	if(defined($arr1[$i]) && defined($arr2[$i])) {
		if($arr1[$i] ne $arr2[$i]) {
			print "$i: $arr1[$i]\n";
			print "$i: $arr2[$i]\n";
			print "====================================================\n\n";
		}
	} elsif(defined($arr1[$i])) {
		print "$i: $arr1[$i]\n";
		print "$i: \n";
		print "====================================================\n\n";
	} else {
		print "$i: \n";
		print "$i: $arr2[$i]\n";
		print "====================================================\n\n";
	}
}
