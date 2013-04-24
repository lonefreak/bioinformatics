#! /usr/bin/perl

# MIRROR
# populate_sequence_table.pl 0.1
# Author: Fabricio Leotti
# Created at: 23/abr/2013
# Updated at: 23/abr/2013
# Description: Extract a random subset of sequences from <copy_to fasta file> and insert the data into a named MySQL table
# Usage: $ ./mirror_populate_sequence_table.pl <copy_to fasta file> [<copy_to fasta file> [<copy_to fasta file> [...]]] <database> <table>

use strict;
use DBD::mysql;

my ($USAGE) = "\nUSAGE: $0 <copy_to fasta file> [<copy_to fasta file> [<copy_to fasta file> [...]]] <database> <table>\n";

if (!defined($ARGV[0]) || !defined($ARGV[1]) || !defined($ARGV[2])) {
	die $USAGE;
}

my $table = pop;
my $database = pop;
my @samples = ();
my $total_samples = @ARGV;
my $len = 0;
print "Starting process (",&current_time,")\n";

my $connect = &connect($database);
&truncate($table);
while(@ARGV>0) {
	$len = @ARGV;
	print "Including sample file ",$total_samples-$len+1," of ",$total_samples," (",&current_time,")\n";
	&add_to_collection($table, shift);
}
$len = &count($table);
print "Total samples included: ", $len," (",&current_time,")\n";
exit;

sub add_to_collection {
	my $collection = $_[0];
	my $filename = $_[1];

	my $handler;
        open($handler, "<$filename") || die "cannot open fasta file $filename\n";
        while(<$handler>) {
		chomp;
                if($_ =~ m/^>/) {
			my $label = $_;
                        my $position = tell();
                        my $newline = <$handler>;
                        my $current_seq = "";
                        while($newline =~ m/^[^>]/) {
                                chomp($newline);
                                $current_seq .= $newline;
                                $newline = <$handler>;
                        }
			my %seq_data;
			$label =~ s/'/\\'/g;
			$seq_data{$collection} = {
					"label"	=>	$label,
					"seq"	=>	$current_seq,
					"length"=>	length($current_seq)
					};
			&save(\%seq_data);
                        unless(seek($handler,$position,0)) {
                                die "A problem has occured during the processing of the FASTA file $filename";
                        }
                }
        }
        close($handler);
}

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

sub connect {
	my $host = "localhost";
	my $database = $_[0];
	my $user = "root";
	my $pw = "";
	my $connect = DBI->connect("DBI:mysql:database=$database;host=$host",$user, $pw, {RaiseError => 1});
	return $connect;
}

sub truncate {
	my $table = $_[0]; 
	my $query = "truncate table $table";
	my $execute = $connect->do($query);
}

sub count {
	my $table = $_[0];
	my $query = "select count(1) from $table";
	my $q = $connect->prepare($query);
	$q->execute();
	my @result = $q->fetchrow_array();
	return $result[0];
}

sub save {
	my %data = %{$_[0]};

	foreach my $seq (keys(%data)) {
		my $table = $seq;
		my %seq_data = %{$data{$seq}};
		my $delimiter = "'";
		my @fields;
		my @values;
		foreach my $field (keys(%seq_data)) {
			if($field eq "length") { $delimiter = ""; } else { $delimiter = "'"; }
			push(@fields, $field);
			push(@values, $delimiter.$seq_data{$field}.$delimiter);
		}
		my $query = "insert into ".$table." (".join(",",@fields).") values (".join(",",@values).")";
		my $execute = $connect->do($query);
	}
}
