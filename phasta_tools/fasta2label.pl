#!/usr/bin/perl

# fasta2label.pl 1.1
# Author: Fabricio Leotti
# Created at: 
# Updated at: 07/feb/2013
# Description: Extract all labels in a fasta file to a separated file, containing only labels.
# Usage: $ ./fasta2label.pl <input fasta file> <output label file>
# Return: <output label file> created on the software specified folder

use strict;

my ($USAGE) = "\nUSAGE: $0 <input fasta file> <output label file>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1])) {
	die $USAGE;
}

my $fasta = $ARGV[0];
my $label = $ARGV[1];

if (substr($fasta, -5, 5) ne "fasta" && substr($fasta, -3, 3) ne "fna") {
	die "You need to privide a .fasta or .fna file as input\n$USAGE";
}

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
