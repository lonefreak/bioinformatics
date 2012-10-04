#!/usr/bin/perl

use strict;
use warnings;

MAIN:{
	my $newline;
	my $file = $ARGV[0];
	open(FILE, "<$file") || die "cannot open $file\n";
	open(OUT, ">/tmp/table.txt") || die "cannot open /tmp/table.txt\n";
	while(<FILE>) {
		if($_ =~ m/^gi/) { next; }
		chomp;
		print OUT $_;
		my $position = tell();
		if(defined($newline = <FILE>)) {
			chomp($newline);
			if($newline =~ m/^gi/) {
				print OUT "\t$newline\n";
			} else {
				print OUT "\n";
			}
		}
		seek FILE, $position, 0;
	}
	close(FILE);
	close(OUT);
	print "Done!!\n\n";
}
