#!/usr/bin/perl

use strict;

my ($USAGE) = "\nUSAGE: $0 <input fastq file> <output fasta file>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1])) {
	die $USAGE;
}

# retrieve args
my $fastq = $ARGV[0];
my $fasta = $ARGV[1];

&write_fasta;

sub write_fasta {
        my $newline;
	my $label;
        open(FASTQ, "<$fastq") || die "cannot open fastq file $fastq\n";
	open(FASTA, ">$fasta") || die $!;
        while(<FASTQ>) {
		my $position = tell();
                if($_ =~ m/^\@/) {
			$_ =~ s/^\@/>/; 
                        chomp;
                        $newline = <FASTQ>;
			chomp($newline);
			if(!($newline =~ m/^\@/)) {
			#} else {
				print FASTA "$_\n$newline\n";
			}
			seek FASTQ, $position, 0;
                }
        }
	close(FASTQ);
        close(FASTA);
        print "Done!\n\n";
}
