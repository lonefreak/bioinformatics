#!/usr/bin/perl
my $bufsize = shift;
my $file = shift;
my @list = ();

srand();
open(FILE,"<$file") or die "Cannot open file $file\n";
while (<FILE>)
{
    push(@list, $_), next if (@list < $bufsize);
    print "##########\n",$_,"==========\n",rand($. / $bufsize), "\n\n";
    $list[ rand(@list) ] = $_ if (rand($. / $bufsize) < 1);
}
close(FILE);
print foreach @list;
