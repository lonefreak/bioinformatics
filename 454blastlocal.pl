#                                                        
#  PROGRAM: 454blast.pl                                     11.04.2007     
#
#  DESCRIPTION: Blasting reads against a database.       
#
#  AUTHOR: Tatiana Torres
#
#  LAST MODIFIED: 22.05.2012
#                               


#!usr/bin/perl -w

use Bio::Perl;
use Bio::Tools::Run::StandAloneBlast;
use Bio::SearchIO; 
use Bio::SeqIO;
use Bio::DB::Fasta;
use Getopt::Std;
use warnings;
use strict;


### Declare and initialize variables

my $input_seq = my $threads = my $project_name = my $prog = '';
my $db = my $eval = my $id = my $len = '';

my $aln_length = my $perc_id = my $perc_len = 0;
my $l = my $n_seq = my $blast_done = my $n_seq_tot = 0;

my $seq_wo_hit = my $disc_hit = my $aligned_seqs = 0;

my $filt = 'F'; #F -> off, T -> on

my @no_hits_found  = ();

my %opts = my %hit_list = ();

# regex for recovering gene name in the gene description

my $regex1 = "name=(.+?);";

# regex for recovering gene ID in the gene description

my $regex2 = "parent=(.+?);";

# regex for recovering species name in the gene description

my $regex3 = " species=(.+?);";


### Read command line

my ($USAGE) = "\nUSAGE: $0\n".
    	      "\t\t-t Number of threads to use\n".
    	      "\t\t-s Input sequence file - sequences in fasta format\n".
    	      "\t\t-d Database\n".
              "\t\t-n Project name [default = blast_res]\n".
              "\t\t-p Program name [default = blastn]\n".
              "\t\t-e E-value [default = 1e-4]\n".
              "\t\t-i Minimum % identity with database sequence [default = 70]\n".
              "\t\t-l Minimum % of query sequence involved in the alignment [default = 50]\n\n";

getopts('t:s:n:p:d:e:i:l:h', \%opts);
chomp(%opts);

if ($opts{t}) {
   $threads = $opts{t};
   chomp $threads;
}

if ($opts{s}) {
   $input_seq = $opts{s};
   chomp $input_seq;
}

if ($opts{d}) {
   $db = $opts{d};
   chomp $db;
}

if ($opts{n}) {
   $project_name = $opts{n};
   chomp $project_name;
} else { $project_name = "local-p" }

if ($opts{p}) {
   $prog = $opts{p};
   chomp $prog;
} else { $prog = "blastn" }

if ($opts{e}) {
   $eval = $opts{e};
   chomp $eval;
} else { $eval = 1e-4 }

if ($opts{i}) {
   $id = $opts{i};
   chomp $id;
} else { $id = 70 }

if ($opts{l}) {
   $len = $opts{l};
   chomp $len;
} else { $len = 50 }


if (!($input_seq) || !($db)  || ($opts{h})) {
	print $USAGE;
	exit;
}


### Create new directory to store new files

mkdir $project_name || die "Could not create folder $project_name\n";


### Output files

my $out_table = $project_name."/".$project_name."-table.txt";
my $summary   = $project_name."/".$project_name."-summary.txt";

my $mapped_seq = $project_name."/".$project_name."-mapped.fasta";
my $not_mapped = $project_name."/".$project_name."-not_mapped.fasta";


### Open output files

# Table with mapping information for each query sequence 
open(TABLE, ">$out_table") || die "Could not open file $out_table.\n";

print TABLE "QUERY\t#HITS\tBEST_HIT\tPARENT\tE-VALUE\tID\tHIT_START\tHIT_END\tGENE_NAME\tSPECIES\t".
				           "2ND_HIT\tPARENT\tE-VALUE\tID\tHIT_START\tHIT_END\tGENE_NAME\tSPECIES\n";

# Blast results
my $blast_res = $project_name."/".$project_name.'-blast_res.out';

# Discarded hits and summary statistics 
open(SUMM, ">$summary") || die "Could not open file $summary.\n";
(my $sec, my $min, my $hour, my $day, my $month, my $year) = (localtime)[0..5];
printf SUMM "\n%s %s  %02d.%02d.%04d  %02d:%02d:%02d %s\n\n", 
			'=' x 20 .'[', $0, $day, $month+1, $year+1900, $hour, $min, $sec, ']'.'=' x 20;
print  SUMM	"INPUT FASTA FILE:      $input_seq\n",
			"DATABASE:        		$db\n".
			"BLAST PROGRAM NAME:    $prog\n".
            "E-VALUE THRESHOLD:     $eval\n".
            "ID THRESHOLD:	        $id\n".
            "MIN % OF QUERY IN ALN: $len\n\n";

print  SUMM	"DISCARDED HITS:\n\n";


### Create SeqIO objects to read in and write out

my $in_seq_obj  = Bio::SeqIO->new(-file => $input_seq, -format => "fasta");

my $seq_db = Bio::DB::Fasta->new($input_seq);
$n_seq_tot += scalar($seq_db->get_all_ids);

my $mapped_obj  = Bio::SeqIO->new(-file => ">$mapped_seq", -format => 'fasta');
my $nmapped_obj = Bio::SeqIO->new(-file => ">$not_mapped", -format => 'fasta');


### Blast 

my @blast_params = (
					program  => $prog,
					database => $db,
					e => $eval,
					v => 10,
					b => 10,
					F => $filt,
					o => $blast_res,
					a => $threads, 
				   );

my $blast_obj = Bio::Tools::Run::StandAloneBlast->new(@blast_params);

my $blast_report = $blast_obj->blastall($input_seq);

print "\n\nBLAST DONE!\nNOW PARSING.\n\n";

# For each read, a new result
while (my $result_obj = $blast_report->next_result) {

	my $n_hits = $result_obj->num_hits;

	# If no hit is found for a given sequence, go to the next result 
	# and keep a list of reads with no hit	
	
	unless ($n_hits) { # print seqs without hits in a file
	
		++$seq_wo_hit;
		
		my $seq_obj_wo_hit = $seq_db->get_Seq_by_id($result_obj->query_name);
		$nmapped_obj->write_seq($seq_obj_wo_hit);
				
		next; 	
	}


	my $hit = $result_obj->next_hit;  # Get the first (best) hit
	my $hsp_best = $hit->next_hsp('best'); 
	$aln_length = $hsp_best->length('query');
	
	$perc_len = ($aln_length/$result_obj->query_length) * 100;
	$perc_id  = $hsp_best->percent_identity;

	my $bitscore_1st = $hsp_best->bits();

	# Keep only hits with >= $id_threshold identity over at least  
	# $len_threshold of the read length

	if ($perc_id >= $id && $perc_len >= $len) {
		
		++$aligned_seqs;
		
		$hit->description =~ /$regex1/;
		my $gene_name = $1;
		
		$hit->description =~ /$regex2/;
		my $parent = $1;

		$hit->description =~ /$regex3/;
		my $species_name = $1;		
		
		print TABLE $result_obj->query_name . "\t" . # sequence name
					$n_hits . "\t" .                 # number of hits
					$hit->name . "\t" .              # subject name
					$parent . "\t" .                 # parent name					
					$hsp_best->evalue . "\t" .       # e-value
					$perc_id . "\t" .                # % identical
					$hsp_best->start('hit') . "\t" . # start position from alignment
					$hsp_best->end('hit') . "\t" .   # end position from alignment
					$gene_name . "\t" .              # gene name
					$species_name . "\t" ;           # species name

		my $seq_obj_w_hit = $seq_db->get_Seq_by_id($result_obj->query_name);		
		$mapped_obj->write_seq($seq_obj_w_hit);

	} else { # print seqs with discarded hits in a file		
	
		my $seq_obj_disc = $seq_db->get_Seq_by_id($result_obj->query_name);		
		$nmapped_obj->write_seq($seq_obj_disc);
			
		++$disc_hit;
		
		print SUMM	"QUERY         : ",$result_obj->query_name,"\n",
					"QUERY LENGTH  : ",$result_obj->query_length,"\n",
					"HIT LENGTH    : ",$aln_length,"\n",
					"PERCENT LENGTH: ",$perc_len,"\n",
					"IDENTITY      : ",$perc_id,"\n",
					"SCORE         : ",$hsp_best->score(), "\n\n";
		next; 			
	}	
	
	if ($n_hits > 1) {
		
		my $hit_2nd   = $result_obj->next_hit;  # Get the second hit
		my $hsp_best2 = $hit_2nd->next_hsp('best'); 
		$aln_length = $hsp_best2->length('query');
		
		$perc_len = ($aln_length/$result_obj->query_length) * 100;
		$perc_id  = $hsp_best2->percent_identity;
				
		# Keep only hits with >= $id_threshold identity over at least  
		# $len_threshold of the sequence length
		if ($perc_id >= $id && $perc_len >= $len) {
		
			$hit_2nd->description =~ /$regex1/;
			my $gene_name2 = $1;
		
			$hit_2nd->description =~ /$regex2/;
			my $parent2 = $1;
	
			$hit_2nd->description =~ /$regex3/;
			my $species_name2 = $1;		
												
			print TABLE $hit_2nd->name . "\t" .           # subject name
						$parent2 . "\t" .                 # parent name
						$hsp_best2->evalue . "\t" .       # e-value
						$perc_id . "\t" .                 # % identical
						$hsp_best2->start('hit') . "\t" . # start position from alignment
						$hsp_best2->end('hit') . "\t" .   # end position from alignment
						$gene_name2 . "\t" .              # gene name
						$species_name2 . "\n" ;           # species name

	
		} else { print TABLE "\n"; }
	
	} else { print TABLE "\n"; }	

}	

			
print  SUMM "\nTOTAL NUMBER OF SEQUENCES  : $n_seq_tot.\n",
			"NUM OF SEQS WITH NO HIT    : $seq_wo_hit.\n",
			"NUM OF DISCARDED HITS      : $disc_hit.\n",
			"NUMBER OF SEQS ALIGNED     : $aligned_seqs.\n",
			"NUMBER OF SEQS NOT ALIGNED : ", $seq_wo_hit+$disc_hit, ".\n\n";
	
print  	  "\nTOTAL NUMBER OF SEQUENCES  : $n_seq_tot.\n",
			"NUM OF SEQS WITH NO HIT    : $seq_wo_hit.\n",
			"NUM OF DISCARDED HITS      : $disc_hit.\n",
			"NUMBER OF SEQS ALIGNED     : $aligned_seqs.\n",
			"NUMBER OF SEQS NOT ALIGNED : ", $seq_wo_hit+$disc_hit, ".\n\n";	
	
($sec, $min, $hour) = (localtime)[0..5];
printf SUMM "\n\nEnd of run %02d:%02d:%02d %s\n\n", $hour, $min, $sec, '=' x 62;


close TABLE; close SUMM;



exit;
	
	



