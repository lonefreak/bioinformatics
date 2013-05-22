#!/usr/bin/perl -w

#                                                        
#  PROGRAM: hits_distribution.pl                                     18.Oct.2012     
#
#  DESCRIPTION: Counts the number of hits for each distinct user-provided key
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 22.Mai.2013
#  

use MongoDB;
use MongoDB::OID;
use Time::HiRes qw(gettimeofday);

my ($USAGE) = "\nUSAGE: $0 <db> <collection> <max e-value> <min identity> <origin> <distinct key> <output file>\n".
              "\t\t<db> MongoDB database name\n".
              "\t\t<collection> MongoDB collection to use\n".
              "\t\t<max e-value>\n".
	      "\t\t<min identity>\n".
	      "\t\t<origin> 'origin' tag in the collection\n".
	      "\t\t<distinct key> the collection key that will be used for the distinct query\n".
	      "\t\t<output file> a name for the csv output file\n";

unless($ARGV[0] && $ARGV[1] && $ARGV[2] && $ARGV[3] && $ARGV[4] && $ARGV[5] && $ARGV[6]) { die $USAGE; }

my $DATABASE = $ARGV[0];
my $COLLECTION = $ARGV[1];
my $EVALUE = $ARGV[2] + 0.0;
my $IDENTITY = $ARGV[3] + 0.0;
my $ORIGIN = $ARGV[4];
my $KEY = $ARGV[5];
my $OUTPUTFILE = $ARGV[6];

open(OUT, ">$OUTPUTFILE.csv") || die "Could not open file $OUTPUTFILE.csv.\n";
open(LOG, ">hits_distribution.log") || die "Could not create log file.\n";

print LOG "###########################################\n";
print LOG "Starting process (",&current_time,")\n";
print LOG "###########################################\n";

my $conn = MongoDB::Connection->new;
my $db = $conn->$DATABASE;
my $chom = $db->$COLLECTION;

my $ltoperator = '$lt';
if($EVALUE == 0) {
	$ltoperator = '$lte';
}

my $total_hits = $chom->count({
	"origin" => "$ORIGIN",
	"evalue" => {$ltoperator=> $EVALUE},
	"id" => {'$gte' => $IDENTITY}
	});
print LOG "Total hits found: $total_hits\n";
print LOG "Starting distinct query by key $KEY (",&current_time,")\n";
my $hits = $db->run_command([ 
    	"distinct" => "$COLLECTION", 
    	"key"      => "$KEY", 
    	"query"    => {
		"origin" => "$ORIGIN",
		"evalue" => {$ltoperator => $EVALUE},
		"id" => {'$gte' => $IDENTITY}
	}]); 
print LOG "Distinct query done (",&current_time,")\n";
print LOG "Starting counting hits process.\n";
for my $hit ( @{ $hits->{values} } ) { 
	print LOG "Counting $hit hits...\t\t";
	my $hitcount = $chom->count({
		"origin" => "$ORIGIN",
		"$KEY" => "$hit",
		"evalue" => {$ltoperator => $EVALUE},
		"id" => {'$gte' => $IDENTITY}
		});
	print LOG "$hitcount\n";
	print OUT "$hitcount,$hit\n"; 
}
print LOG "Count process done\n";
print LOG "###########################################\n";
print LOG "Hits distribution done (",&current_time,")\n";
print LOG "###########################################\n";
exit;

sub current_time {
        my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
        (my $second, my $minute, my $hour, my $dayOfMonth, my $month, my $yearOffset, my $dayOfWeek, my $dayOfYear, my $daylightSavings) = localtime();
        my $year = 1900 + $yearOffset;

        ($second, $minute, $hour, $dayOfMonth) = (&add_trailing_zero($second), &add_trailing_zero($minute), &add_trailing_zero($hour), &add_trailing_zero($dayOfMonth));

        my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
        return $theTime;
}

sub add_trailing_zero {
        if($_[0] >= 0 && $_[0] <= 9) {
                return "0$_[0]";
        }
        return $_[0];
} 
