#                                                        
#  PROGRAM: 454blastlocal.pl                                     11.04.2007     
#
#  DESCRIPTION: Blasting reads against a database.       
#
#  AUTHORS: Tatiana Torres e Fabricio Leotti
#
#  LAST MODIFIED: 04.10.2012
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

### Declare and initialize empty variables
my $aln_length = my $perc_id = my $perc_len = 0;
my $n_seq = my $blast_done = my $n_seq_tot = 0;
my $seq_wo_hit = my $disc_hit = my $aligned_seqs = 0;
my @no_hits_found  = ();
my %opts = my %hit_list = ();

### Declaring and initializing default variables
my %blast_options(
	threads => "",
	input_fasta => "",
	database => "",
	project_name => "local-p",
	blast_program => "blastn",
	evalue => 1e-4,
	min_identity => 70,
	min_length => 50,
	filter => "F" #F -> off, T -> on
);

### TO-DO: CONSIDER DIFERENT TYPES OF OUTPUT FIELDS
# regex for recovering gene name in the gene description
#my $regex1 = "name=(.+?);";
# regex for recovering gene ID in the gene description
#my $regex2 = "parent=(.+?);";
# regex for recovering species name in the gene description
#my $regex3 = " species=(.+?);";


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

my %accepted_options(
	t => "threads",
	s => "input_fasta",
	d => "database",
	n => "project_name",
	p => "blast_program",
	e => "evalue",
	i => "min_identity",
	l => "min_length"
);

### Setting options to corresponding keys in blast_options
foreach $key (keys(%opts)) {
	if($opts{$key}) {
		$blast_options{$accepted_options{$key}} = $opts{$key};
		chomp($blast_options{$accepted_options{$key}}); 
	}
}

### Checking mandatory options or cry for help!
if(!$blast_options{input_fasta} || !$$blast_options{database} || $opts{h}) {
	die $USAGE;
}

### Create new directory to store new files
mkdir $blast_options{project_name} || die "Could not create folder $blast_options{project_name}\n";

### Output files
my $output_dir = $blast_options{project_name}."/".$blast_options{project_name};
my $out_table = $output_dir."-table.txt";
my $summary   = $output_dir."-summary.txt";
my $mapped_seq = $output_dir."-mapped.fasta";
my $not_mapped = $output_dir."-not_mapped.fasta";
my $blast_res = $output_dir.'-blast_res.out';

### Open output files

# Table with mapping information for each query sequence 
open(TABLE, ">$out_table") || die "Could not open file $out_table.\n";
# Log file
open(LOG, ">/tmp/blop.log") || die "Could not open file /tmp/blop.log.\n";
# Discarded hits and summary statistics
open(SUMM, ">$summary") || die "Could not open file $summary.\n";

print TABLE "QUERY\t#HITS\tBEST_HIT\tE-VALUE".
        "\tID\tHIT_START\tHIT_END".
        "\t2ND_HIT\tE-VALUE\tID\tHIT_START".
        "\tHIT_END\n";

### Writting summary file header
(my $sec, my $min, my $hour, my $day, my $month, my $year) = (localtime)[0..5];
printf SUMM "\n%s %s  %02d.%02d.%04d  %02d:%02d:%02d %s\n\n", 
			'=' x 20 .'[', $0, $day, $month+1, $year+1900, $hour, $min, $sec, ']'.'=' x 20;
print  SUMM  "INPUT FASTA FILE:		$blast_options{input_fasta}\n",
             "DATABASE:			$blast_options{database}\n".
             "BLAST PROGRAM NAME:	$blast_options{blast_program}\n".
             "E-VALUE THRESHOLD:	$blast_options{evalue}\n".
             "ID THRESHOLD:		$blast_options{min_identity}\n".
             "MIN % OF QUERY IN ALN:	$blast_options{min_length}\n\n";
print  SUMM  "DISCARDED HITS:\n\n";


### Create SeqIO objects to read in and write out
my $in_seq_obj  = Bio::SeqIO->new(-file => $blast_options{input_fasta}, -format => "fasta");
my $seq_db = Bio::DB::Fasta->new($blast_options{input_fasta});
$n_seq_tot += scalar($seq_db->get_all_ids);
my $mapped_obj  = Bio::SeqIO->new(-file => ">$mapped_seq", -format => 'fasta');
my $nmapped_obj = Bio::SeqIO->new(-file => ">$not_mapped", -format => 'fasta');


### Blast 
my @blast_params = (
		program  => $blast_options{blast_program},
		database => $blast_options{database},
		e => $blast_options{evalue},
		F => $blast_options{filter},
		a => $blast_options{threads}, 
		v => 10,
		b => 10,
		o => $blast_res
);

my $blast_obj = Bio::Tools::Run::StandAloneBlast->new(@blast_params);
my $blast_output = $blast_obj->blastall($blast_options{input_fasta});

print "\n\nBLAST DONE!\nNOW PARSING.\n\n";
print LOG "\n\nBLAST DONE!\nNOW PARSING.\n\n";

# For each read, a new result
while (my $result = $blast_output->next_result) {
	my $n_hits = $result->num_hits;
	unless ($n_hits) { # print seqs without hits in a file
		++$seq_wo_hit;
		my $seq_obj_wo_hit = $seq_db->get_Seq_by_id($result->query_name);
		$nmapped_obj->write_seq($seq_obj_wo_hit);
		next; 	
	}

	my $hit = $result->next_hit;  # Get the first (best) hit

	if(defined($hit) && defined(my $hsp_best = $hit->next_hsp('best'))) {
		print LOG "Processing sequence ".$result->query_name." with ".$hit->num_hsps()." hits.\n";
		print "Processing sequence ".$result->query_name." with ".$hit->num_hsps()." hits.\n";
		my $hsp_best = $hit->next_hsp('best'); 
		$aln_length = $hsp_best->length('query');
		$perc_len = ($aln_length/$result->query_length) * 100;
		$perc_id  = $hsp_best->percent_identity;
		my $bitscore_1st = $hsp_best->bits();

		# Keep only hits with >= identity_threshold identity over at least  
		# min_length_threshold of the read length
		if ($perc_id >= $blast_options{min_identity} && $perc_len >= $blast_options{min_length}) {
			++$aligned_seqs;

		### TO-DO: CONSIDER DIFERENT TYPES OF OUTPUT FIELDS
		#$hit->description =~ /$regex1/;
		#my $gene_name = $1;
		#$hit->description =~ /$regex2/;
		#my $parent = $1;
		#$hit->description =~ /$regex3/;
		#my $species_name = $1;		

		print TABLE $result->query_name . "\t" . # sequence name
			$n_hits . "\t" .                 # number of hits
			$hit->name . "\t" .              # subject name
			$hsp_best->evalue . "\t" .       # e-value
			$perc_id . "\t" .                # % identical
			$hsp_best->start('hit') . "\t" . # start position from alignment
			$hsp_best->end('hit') . "\t";   # end position from alignment
		
		my $seq_obj_w_hit = $seq_db->get_Seq_by_id($result->query_name);		
		$mapped_obj->write_seq($seq_obj_w_hit);

		} else { # print seqs with discarded hits in a file		
      			my $seq_obj_disc = $seq_db->get_Seq_by_id($result->query_name);
      			$nmapped_obj->write_seq($seq_obj_disc);
      			++$disc_hit;
      			print SUMM "QUERY         : ",$result->query_name,"\n",
                		   "QUERY LENGTH  : ",$result->query_length,"\n",
                	 	   "HIT LENGTH    : ",$aln_length,"\n",
                	 	   "PERCENT LENGTH: ",$perc_len,"\n",
                	 	   "IDENTITY      : ",$perc_id,"\n",
                	 	   "SCORE         : ",$hsp_best->score(), "\n\n";
      			next; 			
		}

    		if ($n_hits > 1) {
      			my $hit_2nd   = $result->next_hit;  # Get the second hit
      			my $hsp_best2 = $hit_2nd->next_hsp('best');
      			$aln_length = $hsp_best2->length('query');
      			$perc_len = ($aln_length/$result->query_length) * 100;
      			$perc_id  = $hsp_best2->percent_identity;
      			# Keep only hits with >= $id_threshold identity over at least  
      			# $len_threshold of the sequence length
      			if ($perc_id >= $id && $perc_len >= $len) {

				### TO-DO: CONSIDER DIFERENT TYPES OF OUTPUT FIELDS
        	                #$hit_2nd->description =~ /$regex1/;
        	                #my $gene_name2 = $1;
        	                #$hit_2nd->description =~ /$regex2/;
        	                #my $parent2 = $1;
        	                #$hit_2nd->description =~ /$regex3/;
        	                #my $species_name2 = $1;
	
	        		print TABLE $hit_2nd->name . "\t" .           # subject name
	        	            $hsp_best2->evalue . "\t" .       # e-value
	        	            $perc_id . "\t" .                 # % identical
	        	            $hsp_best2->start('hit') . "\t" . # start position from alignment
	        	            $hsp_best2->end('hit') . "\n";   # end position from alignment
	      		} else { print TABLE "\n"; }
	    	} else { print TABLE "\n"; }
	} else {
		print  LOG "[UNDEF BEST HIT FOUND] " . $result->query_name . "\n";
		print  "[UNDEF BEST HIT FOUND] " . $result->query_name . "\n";
	}
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
printf LOG "\n\nEnd of run %02d:%02d:%02d %s\n\n", $hour, $min, $sec, '=' x 62;
close TABLE; 
close SUMM;
exit;
