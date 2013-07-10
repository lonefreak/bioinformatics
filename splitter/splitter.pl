#                                                        
#  PROGRAM: splitter.pl                                     21.May.2012     
#
#  DESCRIPTION: Splits a single fasta file from paired-end library into reverse, forward and unpaired fasta files 
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 10.Jul.2013
# 

#!usr/bin/perl -w
use strict;
use warnings;

my ($USAGE) = 	"\nUSAGE: $0 <file.fasta>\n".
		"OUTPUT: \n\treverse.fasta\n\tforward.fasta\n\tunpaired.fasta\n".
		"DESCRIPTION: Splits a single fasta file from paired-end library into reverse, forward and unpaired fasta files\n\n";

my $file = $ARGV[0];

if (!($file)) {
        print $USAGE;
        exit;
}

my $newline;

my $out1 = "reverse.fasta";
my $out2 = "forward.fasta";
my $out3 = "unpaired.fasta";

open(FILE, "<$file") || die "cannot open $file\n";
open(OUT1, ">$out1") || die "cannot open $file\_reverse\n";
open(OUT2, ">$out2") || die "cannot open $file\_forward\n";
open(OUT3, ">$out3") || die "cannot open $file\_unpaired\n";
while(<FILE>){
    chomp;
    
    if($_ =~ m/.*\.r$/){
      print OUT1 "$_\n";
      $newline = <FILE>; chomp($newline);
      print OUT1 "$newline\n";
      next;
    } elsif($_ =~ m/.*\.f$/){
      print OUT2 "$_\n";
      $newline = <FILE>; chomp($newline);
      print OUT2 "$newline\n";
      next;
    }else{
      print OUT3 "$_\n";
      $newline = <FILE>; chomp($newline);
      print OUT3 "$newline\n";
      next;
    }
}
close(FILE);
