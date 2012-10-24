use strict;
use warnings;
my $file = $ARGV[0];
my $newline;
my $file_name;
my $file_extension;
my $nbr_sequences=0;

my $out1 = "output_sequences.txt";

open(FILE, "<$file") || die "cannot open $file\n";
open(OUT1, ">$out1") || die "cannot open $out1\n";
while(<FILE>){
    chomp;
    
#    if($_ =~ m/^@.*[\.fnr]$/){
    if($_ =~ m/^[ATCGNatcgn]*$/){
#      $newline = <FILE>; chomp($newline);
      print OUT1 length($_)."\t$_\n";
#      print OUT1 length($newline)."\t$newline\n";
      $nbr_sequences++;
#      print $nbr_sequences . " > " . length($newline)." - $newline\n";
#      print "$newline\n";
      print "$_\n";
      next;
    }
    
#    print OUT1 "$_\/1\n";
#    print OUT2 "$_\/2\n";
#    my $newline = <FILE>; chomp($newline);
#    print OUT1 substr($newline, 0, length($newline)/2)."\n";
#    print OUT2 substr($newline, length($newline)/2, length($newline)/2)."\n";
#    $newline = <FILE>; chomp($newline);
#    print OUT1 "$newline\/1\n";
#    print OUT2 "$newline\/2\n";
#    $newline = <FILE>; chomp($newline);
#    print OUT1 substr($newline, 0, length($newline)/2)."\n";
#    print OUT2 substr($newline, length($newline)/2, length($newline)/2)."\n";
}
print "Total sequences: ", $nbr_sequences;
close(FILE);
