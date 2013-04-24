#! /usr/bin/perl

# MIRROR
# generate_inserts.pl 0.1
# Author: Fabricio Leotti
# Created at: 24/abr/2013
# Updated at: 24/abr/2013
# Description: Generate a .sql file containing insert statements from at least one fasta file. The inserts will contain the fields 'label', 'seq' and 'length' 
# Usage: $ ./mirror_populate_sequence_table.pl <fasta file> [<fasta file> [<fasta file> [...]]] <database> <table>
# Output: <table>.sql

use strict;

my ($USAGE) = "\nUSAGE: $0 <fasta file> [<fasta file> [<fasta file> [...]]] <database> <table>";

if (@ARGV < 3) {
	die $USAGE;
}

my $table = pop;
my $database = pop;
my @samples = ();
my $total_samples = @ARGV;
my $len = my $tmp_len = my $total_inserts = 0;
print "Starting process (",&current_time,")\n";
my $handler = &sql_header($database,$table);
while(@ARGV>0) {
	$len = @ARGV;
	print "Including file ",$total_samples-$len+1," of ",$total_samples," (",&current_time,")\n";
	$tmp_len = &add_to_file($handler, $table, shift);
	$total_inserts += $tmp_len;
	print "\t$tmp_len inserts generated (",&current_time,")\n";
}
&sql_footer($handler,$table);
print "Total samples included: ", $total_inserts," (",&current_time,")\n";
exit;

sub sql_header {
        my $database = $_[0];
        my $table = $_[1];

	open(my $out, ">$table.sql") || die "cannot open fasta file $table.sql\n";
        print $out "CREATE DATABASE IF NOT EXISTS $database;\n";
        print $out "use $database;\n";
        print $out "DROP TABLE IF EXISTS $table;\n";
        print $out "create table $table (\n";         
	print $out "\tseq_id\tint\tNOT NULL\tAUTO_INCREMENT\tPRIMARY KEY,\n";
	print $out "\tlabel\ttext,\n";
        print $out "\tseq\tlongtext\tNOT NULL,\n";
        print $out "\tlength\tint\tNOT NULL)\n\t\tENGINE=MyISAM;\n";
        print $out "create index index_length on $table(length) using BTREE;\n";
	return $out;
}

sub sql_footer {
	my $out = $_[0];
	my $table = $_[1];

	print $out "delete from $table where length = 0;\n";
        close($out);
}

sub add_to_file {
	my $out = $_[0];
	my $table = $_[1];
	my $filename = $_[2];
	my $index = my $total_inserts = 0;

        open(my $handler, "<$filename") || die "cannot open fasta file $filename\n";
	print $out "insert into $table (label, seq, length) values \n";
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
			print $out "\t('$label','$current_seq',".length($current_seq)."),\n";
			$index++, $total_inserts++;
			unless($index%100) {
				print $out "\t('label','seq',0);\n";
				print $out "insert into $table (label, seq, length) values \n";
				$index = 0;
			}
                        unless(seek($handler,$position,0)) {
                                die "A problem has occured during the processing of the FASTA file $filename";
                        }
                }
        }
        close($handler);
	print $out "\t('label','seq',0);\n";
	return $total_inserts;
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
