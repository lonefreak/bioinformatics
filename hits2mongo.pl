#!/usr/bin/perl -w

#                                                        
#  PROGRAM: hits2mongo.pl                                     24.Sep.2012     
#
#  DESCRIPTION: Inserts blast output hit tables into mongoDB       
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 24.Sep.2012
#  

use MongoDB;
use MongoDB::OID;

my ($USAGE) = "\nUSAGE: $0 <db> <collection> <hit table filename> <origin tag>\n".
              "\t\t<db> MongoDB database name\n".
              "\t\t<collection> MongoDB collection to use\n".
              "\t\t<hit table filename> path and filename for the hit table file\n".
              "\t\t<origin tag> string with the database name and/or type which the BLAST was matched against\n";

unless($ARGV[0] && $ARGV[1] && $ARGV[2] && $ARGV[3]) { die $USAGE; } 

my $DATABASE = $ARGV[0];
my $COLLECTION = $ARGV[1];
my $TABLEFILE = $ARGV[2];
my $ORIGIN = $ARGV[3];

open(TABLE, "<$TABLEFILE") || die "Could not open file $TABLEFILE.\n";

my $conn = MongoDB::Connection->new;
my $db = $conn->$DATABASE;
my $chom = $db->$COLLECTION;

my @rline;
while(<TABLE>){
        chomp;
        @rline = split("\t");
	my %result, my @hits;

	unless($rline[0] eq "QUERY") {
		push @hits, {"hit" => "$rline[2]",
        	                "best_hit" => 1,
        	                "evalue" => $rline[3] + 0.0,
        	                "id" => $rline[4] + 0.0,
        	                "start" => $rline[5] + 0.0,
        	                "end" => $rline[6] + 0.0
        	                };

		if($rline[7]) {
			        push @hits, {"hit" => "$rline[7]",
        	                	"best_hit" => 0,
        	                	"evalue" => $rline[8] + 0.0,
        	                	"id" => $rline[9] + 0.0,
        	                	"start" => $rline[10] + 0.0,
        	                	"end" => $rline[11] + 0.0
        	                };
		}

		$chom->insert({"query" => "$rline[0]",
                                "total_hits" => $rline[1] + 0.0,
				"origin" => $ORIGIN,
                                "hits" => [@hits]});
	}
}
