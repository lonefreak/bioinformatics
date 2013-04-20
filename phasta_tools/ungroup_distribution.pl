#! /usr/bin/perl

open(DIST, "<$ARGV[0]");
open(UNGRP, ">$ARGV[1]");
while(<DIST>) {
	chomp;
	my @line = split("\t",$_);
	for(my $i =0; $i<$line[1]; $i++) {
		print UNGRP $line[0],"\n";
	}
}
close(UNGRP);
close(DIST);
