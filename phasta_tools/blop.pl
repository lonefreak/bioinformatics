#                                                        
#  PROGRAM: blop.pl                                     01.Aug.2012     
#
#  DESCRIPTION: Blast Output Parser       
#
#  AUTHOR: Fabricio Leotti
#
#  LAST MODIFIED: 01.Aug.2012
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

my ($USAGE) = "\nUSAGE: $0\n".
              "\t\t-n Project name [default = blast_res]\n".
              "\t\t-s Input sequence file - sequences in fasta format\n".
              "\t\t-i Input file (BLAST output file) to parse\n";

my ($project_name,$input_report,$input_seq) = ("blast_res","","");
my %opts = ();

getopts('n:i:s:h', \%opts);
chomp(%opts);

if ($opts{n}) {
   $project_name = $opts{n};
   chomp $project_name;
}

if ($opts{i}) {
   $input_report = $opts{i};
   chomp $input_report;
}

if ($opts{s}) {
   $input_seq = $opts{s};
   chomp $input_seq;
}

if (!($input_report) || !($input_seq) || ($opts{h})) {
        print $USAGE;
        exit;
}

my $id = my $len = '';
my $seq_wo_hit = my $aligned_seqs = my $disc_hit = my $n_seq_tot = 0;
my $regex1 = my $regex2 = my $regex3 = '';

### Output folder
mkdir $project_name || die "Could not create folder $project_name\n";
### Output files
my $out_table = $project_name."/".$project_name."-table.txt";
my $summary   = $project_name."/".$project_name."-summary.txt";
my $mapped_seq = $project_name."/".$project_name."-mapped.fasta";
my $not_mapped = $project_name."/".$project_name."-not_mapped.fasta";

### Open output files

# Table with mapping information for each query sequence 
open(TABLE, ">$out_table") || die "Could not open file $out_table.\n";

print TABLE "QUERY\t#HITS\tBEST_HIT\tE-VALUE".
	"\tID\tHIT_START\tHIT_END".
	"\t2ND_HIT\tE-VALUE\tID\tHIT_START".
	"\tHIT_END\n";

# Discarded hits and summary statistics
open(SUMM, ">$summary") || die "Could not open file $summary.\n";
open(LOG, ">/tmp/blop.log") || die "Could not open file /tmp/blop.log.\n";

(my $sec, my $min, my $hour, my $day, my $month, my $year) = (localtime)[0..5];

printf SUMM "\n%s %s  %02d.%02d.%04d  %02d:%02d:%02d %s\n\n",
                        '=' x 20 .'[', $0, $day, $month+1, $year+1900, $hour, $min, $sec, ']'.'=' x 20;
printf LOG "\n%s %s  %02d.%02d.%04d  %02d:%02d:%02d %s\n\n",
                        '=' x 20 .'[', $0, $day, $month+1, $year+1900, $hour, $min, $sec, ']'.'=' x 20;
print SUMM "DISCARDED HITS:\n\n";

# Mapped and not mapped data
my $mapped_obj  = Bio::SeqIO->new(-file => ">$mapped_seq", -format => 'fasta');
my $nmapped_obj = Bio::SeqIO->new(-file => ">$not_mapped", -format => 'fasta');

my $in_seq_obj  = Bio::SeqIO->new(-file => $input_seq, -format => "fasta");

my $seq_db = Bio::DB::Fasta->new($input_seq);
$n_seq_tot += scalar($seq_db->get_all_ids);

my $in = new Bio::SearchIO(-format => 'blast', -file   => $input_report);
while( my $result = $in->next_result ) {
  my $n_hits = $result->num_hits;
  unless ($n_hits) { # print seqs without hits in a file
    ++ $seq_wo_hit;
    my $seq_obj_wo_hit = $seq_db->get_Seq_by_id($result->query_name);
    $nmapped_obj->write_seq($seq_obj_wo_hit);
    next;
  }

  my $hit = $result->next_hit;  # Get the first (best) hit

  if(defined($hit) && defined(my $hsp_best = $hit->next_hsp('best'))) {

    print LOG "Processing sequence ".$result->query_name." with ".$hit->num_hsps()." hits.\n";
    print "Processing sequence ".$result->query_name." with ".$hit->num_hsps()." hits.\n";
    my $aln_length = $hsp_best->length('query');
    my $perc_len = ($aln_length/$result->query_length) * 100;
    my $perc_id  = $hsp_best->percent_identity;
    my $bitscore_1st = $hsp_best->bits();

    # Keep only hits with >= $id_threshold identity over at least  
    # $len_threshold of the read length
    if ($perc_id >= $id && $perc_len >= $len) {
      ++$aligned_seqs;
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

close TABLE;
close SUMM;
