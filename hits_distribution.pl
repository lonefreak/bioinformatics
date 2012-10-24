#!/usr/bin/perl -w

#                                                        
#  PROGRAM: hits_distribution.pl                                     18.Oct.2012     
#
#  DESCRIPTION: Counts the number of hits for each distinct hit
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 18.Oct.2012
#  

use MongoDB;
use MongoDB::OID;

my ($USAGE) = "\nUSAGE: $0 <db> <collection> <max e-value> <min identity> <origin> <output file>\n".
              "\t\t<db> MongoDB database name\n".
              "\t\t<collection> MongoDB collection to use\n".
              "\t\t<max e-value>\n".
	      "\t\t<min identity>\n".
	      "\t\t<output file> a name for the csv output file\n";

unless($ARGV[0] && $ARGV[1] && $ARGV[2] && $ARGV[3] && $ARGV[4]) { die $USAGE; }

my $DATABASE = $ARGV[0];
my $COLLECTION = $ARGV[1];
my $EVALUE = $ARGV[2] + 0.0;
my $IDENTITY = $ARGV[3] + 0.0;
my $ORIGIN = $ARGV[4];
my $OUTPUTFILE = $ARGV[5];

open(OUT, ">$OUTPUTFILE.csv") || die "Could not open file $OUTPUTFILE.csv.\n";

my $conn = MongoDB::Connection->new;
my $db = $conn->$DATABASE;
my $chom = $db->$COLLECTION;

my $ltoperator = '$lt';
if($EVALUE == 0) {
	$ltoperator = '$lte';
}

my $total_hits = $chom->count({
	"origin" => "$ORIGIN",
	"hits.best_hit" => 1,
	"hits.evalue" => {$ltoperator=> $EVALUE},
	"hits.id" => {'$gte' => $IDENTITY}
	});

my $hits = $db->run_command([ 
    	"distinct" => "$COLLECTION", 
    	"key"      => "hits.hit", 
    	"query"    => {
		"origin" => "$ORIGIN",
		"hits.best_hit" => 1,
		"hits.evalue" => {$ltoperator => $EVALUE},
		"hits.id" => {'$gte' => $IDENTITY}
	}]); 

#print OUT "Total hits found: $total_hits\n";
#print OUT "List of all hits found:\n";
for my $hit ( @{ $hits->{values} } ) { 
	my $hitcount = $chom->count({
		"origin" => "$ORIGIN",
		"hits.best_hit" => 1,
		"hits.hit" => "$hit",
		"hits.evalue" => {$ltoperator => $EVALUE},
		"hits.id" => {'$gte' => $IDENTITY}
		});
	print OUT "$hitcount,$hit\n"; 
} 
