#!/usr/bin/perl -w

#                                                        
#  PROGRAM: hits2mongo.pl                                     24.Sep.2012     
#
#  DESCRIPTION: Inserts blast output hit tables into mongoDB       
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 20.Mai.2013
#  

use MongoDB;
use MongoDB::OID;
use Scalar::Util;

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
my $db = $conn->get_database($DATABASE);
my $chom = $db->get_collection($COLLECTION);
my $caption = 1;
my @captions;
my @rline;
while(<TABLE>){
        chomp;

	if($caption) {
#		print $_, "\n";
		@captions = split("\t");
		$caption = 0;
		next;
	}

	
#	print $_, "\n";

        @rline = split("\t");


	my %result, my @hits, my %hit;
	my $col = @rline;
	for (my $i = 0; $i < $col; $i++) {
		my $fkey = &formatted_key($captions[$i]);
		if($fkey eq "2nd_hit") {
			last;
		}
#		print $fkey, " => ", $rline[$i], "\n";
		$hit{$fkey} = (Scalar::Util::looks_like_number($rline[$i]) ? $rline[$i]+0.0 : "$rline[$i]");
	}
	$hit{"origin"} = $ORIGIN;
#	print %hit, "\n";
	$chom->insert(\%hit);
	undef(%hit);
}

sub formatted_key {
	my $key = $_[0];
	$key =~ s/[-#]//g;
	$key = lc($key);
	return $key;
}
