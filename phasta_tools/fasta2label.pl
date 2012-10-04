#!/usr/bin/perl

use strict;

my ($USAGE) = "\nUSAGE: $0 <input fasta file> <output label file>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1])) {
	die $USAGE;
}

my $fasta = $ARGV[0];
my $label = $ARGV[1];

&write_labels;

sub write_labels {
        open(FASTA, "<$fasta") || die "cannot open fasta file $fasta\n";
	open(LABEL, ">$label") || die "cannot open label file $label\n";
        while(<FASTA>) {
		my $position = tell();
                if($_ =~ m/^>/) {
			chomp;
			$_ =~ s/^>//; 
			print LABEL "$_\n";
                }
        }
	close(FASTA);
        close(LABEL);
        print "Done!\n\n";
}
