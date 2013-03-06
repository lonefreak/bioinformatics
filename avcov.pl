#!/usr/bin/perl -w

#                                                        
#  PROGRAM: avcov.pl                                     24.Oct.2012     
#
#  DESCRIPTION: 
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 24.Oct.2012
#  

use MongoDB;
use MongoDB::OID;

my ($USAGE) = "\nUSAGE: $0 <db> <collection> <max e-value> <min identity> <origin> <hit> <stats file>\n";

unless($ARGV[0] && $ARGV[1] && $ARGV[2] && $ARGV[3] && $ARGV[4] && $ARGV[5] && $ARGV[6]) { die $USAGE; }

my $DATABASE = $ARGV[0];
my $COLLECTION = $ARGV[1];
my $EVALUE = $ARGV[2] + 0.0;
my $IDENTITY = $ARGV[3] + 0.0;
my $ORIGIN = $ARGV[4];
my $HIT = $ARGV[5];
my $STATSFILE = $ARGV[6];

open(STATS, "<$STATSFILE") || die "Could not open file $STATSFILE\n";  

my $conn = MongoDB::Connection->new;
my $db = $conn->$DATABASE;
my $chom = $db->$COLLECTION;

my $ltoperator = '$lt';
if($EVALUE == 0) {
	$ltoperator = '$lte';
}

my %qry_hsh;
#for $orgn (@origin) {
my $queries = $db->run_command([
        "distinct" => "$COLLECTION",
        "key"      => "query",
        "query"    => {
                "origin" => "$ORIGIN",
		"hits.hit" => "$HIT",
                "hits.best_hit" => 1,
                "hits.evalue" => {$ltoperator => $EVALUE},
                "hits.id" => {'$gte' => $IDENTITY}
        }]); 

for my $query ( @{ $queries->{values} } ) {
	$qry_hsh{$query} = 1;
} 

my $counter = my $avg = 0;
my $len_sum = my $len_avg = my $max_len = 0;
my $sum = 0.0;
while(<STATS>) {
	chomp;
	my @line = split(" ",$_);
	#print join("#",@line),"\n";
	if(defined($qry_hsh{$line[0]})) {
		$counter++;
		$sum += $line[5];
		#print "$line[0] : $line[5]\n";

		$len_sum += $line[1];
		if($line[1] > $max_len) { $max_len = $line[1]; }
	}
}

if($counter) {
	$avg = $sum / $counter;
	$len_avg = $len_sum / $counter;
}

print "Hit: $HIT ($ORIGIN)\n";
print "Total contigs: $counter\n";
print "Avg coverage: $avg\n";
print "Avg Length: $len_avg\n";
print "Max Length: $max_len\n";

my $cursor = $chom->find({
                "origin" => "$ORIGIN",
                "hits.hit" => "$HIT",
                "hits.best_hit" => 1,
                "hits.evalue" => {$ltoperator => $EVALUE},
                "hits.id" => {'$gte' => $IDENTITY}
        });
my $id_counter = my $id_sum = my $id_avg = 0;
while (my $object = $cursor->next) {
	$id_counter++;
	$id_sum += $object->{"hits"}[0]->{"id"};
}

if($id_counter) {
	$id_avg = $id_sum / $id_counter;
}
print "Avg Id: $id_avg\n";

close(STATS);
exit;
