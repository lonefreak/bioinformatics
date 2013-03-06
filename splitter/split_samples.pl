#! /usr/bin/perl -w
use warnings;
use Data::Dumper;
my $file = $ARGV[0]; 
#input fasta file generated with qiime split_libraries.py
my $mapping_file = $ARGV[1];
#mapping file ised in qiime

my $newline;

my $out1 = "reverse.fasta";
my $out2 = "forward.fasta";
my $out3 = "unpaired.fasta";

open(FILE, "<$file") || die "cannot open $file\n";
open(MAP, "<$mapping_file") || die "cannot open $mapping_file\n";

my %categories;
my %sequencias ;
my $map_index = 0;
while(<MAP>) {
	my @map_line = split("\t",$_);
	if($map_index > 0 ) {
		$categories{$map_line[0]} = 1;	
	}
	$map_index++;
}

my %file_handlers;

while(<FILE>){
	chomp;
	my @category = split("_", $_);
	my $cat = substr($category[0],1,length($category[0])-1);
	my $label = $_;
	$newline = <FILE>; chomp($newline);
	$sequencias{$cat}{$label} = $newline;
}

foreach $c (keys(%sequencias)) {
	open(OUT,">$c.fna");
	foreach $item (keys(%{ $sequencias{$c} })) {
		print OUT $item, "\n", $sequencias{$c}{$item}, "\n";
		print $item, "\n", $sequencias{$c}{$item}, "\n";
	}
	close(OUT);
}

close(FILE);
