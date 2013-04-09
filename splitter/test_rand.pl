#! /usr/bin/perl -w

my $r = rand();
print "$r\n";
$r = rand(2);
print "$r\n";
my @a = ();

for(my $i=0; $i<10; $i++) {
$r = rand(@a);
print $r, "\n";
$a[$r] = $r;
}
my $l = @a;
print $l,"\n##########\n";
for(my $i=0; $i<length(@a); $i++) {
  print $a[$i],"\n";
}
