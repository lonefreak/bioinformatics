#!/usr/bin/perl -w

#REFinder.plx scans unassembled genomic sequences for tandem repetitive elements (REs). This program works by building contigs around a set of user-provided sequences (in FASTA format) using BLAST. Each time the contig is extended, a BLAST search is performed to check if the sequence being added to the contig aligns elsewhere in the existing contig, and thereby identifies RE motifs.#

#Written by David A. Rasmussen - 2009# 

use warnings;

#User-defined variables
my $blastdb = "scuttleseq"; #sequence file to search when building contigs (must be formatted as a BLAST database)
my $evalue = "1e-25"; #e-value to use when finding contiguous sequences
my $maxout = 30; #upper limit on number of times the program will try to extend the contig
my $evalue2 = "1e-5"; #e-value to use when using blast to check if extended contig aligns with itself (repeats)

#Get fasta sequence file with starting repeat sequences
my $seq_file = $ARGV [0]; #Put filename of FASTA sequences
open (SEQFILE, "<$seq_file") or die "ERROR: Enter sequence file at command line\n";
open (LIST, ">scut_REs_e25e5"); #main output is stored in this  file

my $line_read = <SEQFILE>;
my $header = '';
my $sequence = '';

MAIN: until (eof (SEQFILE)) {
	&get_next_seq;

	$qlength = length $sequence; #$qlength is used later in the extendcontig algoirithm
	$repcount = 0;
	$kill = 0;
	$i = 0;
	$extensioncheck = 0;
	open (TEMP, ">tempfile");  # make temporary file from which to BLAST this one sequence
	#print TEMP $header;
	print TEMP $sequence."\n";
	close TEMP;
	system "blastall -p blastn -d $blastdb -i tempfile -o outputfile1 -e $evalue -m8";
	system "blastall -p blastn -d $blastdb -i tempfile -o outputfile2 -e $evalue -m0";
	open (BLASTOUT8, "<outputfile1");
	open (BLASTOUT0, "<outputfile2");
	if (eof(BLASTOUT8)) {    # check if BLASTed to nothing
		next MAIN;
	    } else {
		&extendcontig;
	    }
	close BLASTOUT8;
	close BLASTOUT0;
	
	until ($kill == 1) { #if $kill returns as 1, contig could not be extended further
	print "$newpart = new\n\n";
	print "$oldpart = old\n\n";
	$offset = length($newpart);
	    if ($extensioncheck >= length($extended_seq)) {
		$kill = 1;
	    }
	    $i++;
	    if ($i > $maxout) { #upper limit on the number of times the program will attempt to extend the contig
		$kill = 1;
	    }
	open (TEMPBLAST, ">tempblastfile"); #make temporary BLAST db
	open (TEMPQUERY, ">tempqueryfile"); #make a temporary file for new BLAST query
	print TEMPBLAST $header;
	print TEMPBLAST $oldpart."\n";
	close TEMPBLAST;
	system "formatdb -i tempblastfile -pF"; #format temp BLAST db
	print TEMPQUERY $newpart."\n";
	close TEMPQUERY;
	system "blastall -p blastn -d tempblastfile -i tempqueryfile -o outputfile3 -e $evalue2 -m8";

	open (BLASTREPCHECK, "<outputfile3");
	#see if new seq blasted to old seq, get repetitive sequence motif
	unless (eof (BLASTREPCHECK)) {
	    $repcount++;
	    @rep_start = ( );
	    @rep_end = ( );
	    $blastline = <BLASTREPCHECK>;
	    @rep_start = (split(/\s+/, $blastline)) [8];
	    $repstart = "@rep_start";
	    @rep_end = (split(/\s+/, $blastline)) [9];
            $repend = "@rep_end";
	    print "$repend and $repstart = repend or start\n\n";
	    if ($bestdirection == 3) {
		$repmotif = substr ($extended_seq, ($repstart - $offset - 1));
	    } if ($bestdirection == 5) {
		$repmotif = substr ($extended_seq, 0, ($offset + $repend - 1));
	    }
	    print "$repmotif = motif\n\n";
	    $kill = 1;
	}
	close BLASTREPCHECK;
	
	$sequence = "$extended_seq";
	$qlength = length $extended_seq;
	$extensioncheck = length($extended_seq);
	open (EXTENSION, ">extensionfile");
	print EXTENSION $extended_seq."\n";
	close EXTENSION;
        system "blastall -p blastn -d $blastdb -i extensionfile -o outputfile1 -e $evalue -m8";
        system "blastall -p blastn -d $blastdb -i extensionfile -o outputfile2 -e $evalue -m0";
        open (BLASTOUT8, "outputfile1");
        open (BLASTOUT0, "outputfile2");
	if (eof(BLASTOUT8)) { #check if BLASTed to nothing
	    $kill = 1;
	} else {
	    &extendcontig;
	}
	close BLASTOUT8;
	close BLASTOUT0;
    } #end while ($kill == 0) loop

	     if ($repcount > 0) {
		 print LIST $header;
		 print LIST $repmotif."\n";
	     }
}#end until(eof (SEQFILE)) loop

        close SEQFILE;
	close LIST;
	exit;




###########SUBROUTINES############


sub get_next_seq {
    $header = $line_read;
    my $hit = 0;
    $sequence = "";
    while ($hit==0) {
	$line_read = <SEQFILE>;
	if (($line_read =~ /^>/) || (eof(SEQFILE))) {
	    $hit = 1;
	} else {
	    $sequence .= $line_read;
	    chomp $sequence;
	    $sequence =~ s/\s//g;  # eliminate extra whitespace
	} # end if/ else
    } # end while ($hit==0)
} # end sub get_next_seq  Note, the sequence does NOT end with enter


sub extendcontig {         

#Store each hit in an  array, eliminating duplicate subjects          
    
    @listhits = ( );
    @hits = ( );
    @listhits = qw ( XXXXXXXXXXXXX YYYYYYYYYYYYYY );
while(<BLASTOUT8>) {
    chomp;
    my $line = $_;
    if ($line =~ /1_0/) {
	@allhits = (split(/\s+/, $line)) [1];
       push (@listhits, @allhits);
    } if ($line =~ /1_0/) {
       push (@hits, $line);
    }
    if (($listhits[-1]) eq ($listhits[-2])) {
	pop @hits;
    } #pop @hits eliminates duplicate subjects from single hits
} #end while loop

#Parse Subject ID, Query Start, Query End, Subject Start and Subject End from each alignment

    @subjects = ( );
    @qstarts = ( );
    @qends = ( );
    @sstarts = ( );
    @sends = ( );

foreach $var (@hits) {

    @subj_id = '';
    @subj_id = (split(/\s+/, $var)) [1];
    push (@subjects, @subj_id);
    @query_start = '';
    @query_start = (split(/\s+/, $var)) [6];
    push (@qstarts, @query_start);
    @query_end = '';
    @query_end = (split(/\s+/, $var)) [7];
    push (@qends, @query_end);
    @subj_starts = '';
    @subj_starts = (split(/\s+/, $var)) [8];
    push (@sstarts, @subj_starts);
    @subj_end = '';
    @subj_end = (split(/\s+/, $var)) [9];
    push (@sends, @subj_end);
} #end foreach

    @newhits = ( );
while (<BLASTOUT0>) {
    chomp;
    my $line = $_;
    if ($line =~ />/) {
	push (@newhits, $line);
    } else {
	next;
    }
} #end while loop

    @subjlengths = ( );
foreach $varb (@newhits) {
    @pre = (split(/\s+/, $varb)) [1];
    $post = join( '', @pre);
    $length = substr($post, 7);
    push (@subjlengths, $length);
}

#Find the the BLAST hit with the most overhang
    $score = '';
$prev_score = 0;
$n = $#hits;
for ( $count = 0; $count <= $n; $count++ ) {
    if (($sends[$count]) >= ($sstarts[$count])) {
	$switch = '1'; #subj sequence is orientated 5' to 3'
    } elsif (($sends[$count]) < ($sstarts[$count])) {
	$switch = '2'; #subj sequence is orientated 3' to 5'
    }

    if ($switch == 1) {
	$score_3prime = (($subjlengths[$count] - $sends[$count]) - ($qlength - $qends[$count]));
	$score_5prime = ($sstarts[$count] - $qstarts[$count]);
	if ($score_3prime >= $score_5prime) {
	    $score = $score_3prime;
	    $direction = '3';
	} else {
	    $score = $score_5prime;
	    $direction = '5';
	}
    } #end if ($switch ==1)

    if ($switch == 2) {
	$score_3prime = (($sends[$count]) - ($qlength - $qends[$count]));
	$score_5prime = (($subjlengths[$count] - $sstarts[$count]) - ($qstarts[$count]));
	if ($score_3prime >= $score_5prime) {
	    $score = $score_3prime;
	    $direction = '3';
	} else {
	    $score = $score_5prime;
	    $direction = '5';
	}
    } #end if ($switch == 2)
    #print "$score = current score";
    if ($score > $prev_score) {
	$prev_score = $score;
	$besthit = $count;
	$bestscore = $score;
	$bestswitch = $switch;
	$bestdirection = $direction;
	$best_qend = $qends[$count];
	$best_send = $sends[$count];
	$best_qstart = $qstarts[$count];
	$best_sstart = $sstarts[$count];
	$best_subjlength = $subjlengths[$count];
    }
} #end for loop

    if ($bestscore <= 10) { #if best score is less than or = to 10, exit unless loop in MAIN 
        $kill = 1;
	return $kill;
    }

#Get sequence for BLAST hit with the most overhang
$bestID = $subjects[$besthit];
system "./getseq.plx $blastdb $bestID";
open (NEWSEQ, "seq.txt") or die "ERROR: file not found.\n\n";
    $newseq = '';
    while (<NEWSEQ>) {
	$line = $_;
	if ($line =~ />/) {
	    next;
	} else {
	    $newseq .= $line;
	    chomp $newseq;
	    $newseq =~ s/\s//g;
	}
    } #end while (<NEWSEQ>)
    close NEWSEQ;

#Extend sequence by concatenating to best BLAST hit
    if (($bestswitch == '1') && ($bestdirection == '3')) {
	$oldpart = substr($sequence, 0, $best_qend);
	$newpart = substr($newseq, $best_send);
	$extended_seq = $oldpart . $newpart;
    }
    if (($bestswitch == '1') && ($bestdirection == '5')) {
	$oldpart = substr($sequence, ($best_qstart - 1));
	$newpart = substr($newseq, 0, ($best_sstart -1));
	$extended_seq = $newpart . $oldpart;
    }
    if (($bestswitch == '2') && ($bestdirection == '3')) {
	$revseq = reverse $newseq; #reverse sequence                                                                                
	$revseq =~ tr/ACGTacgt/TGCAtgca/; #complement sequence                                                                        
	#print "$revseq = this is the reverse complement\n\n";
	$oldpart = substr($sequence, 0, $best_qend); #used to be $best-1
	$newpart = substr($revseq, ($best_subjlength - $best_send + 1));
	$extended_seq = $oldpart . $newpart;
    }
    if (($bestswitch == '2') && ($bestdirection == '5')) {
	$revseq = reverse $newseq; #reverse sequence
	$revseq =~ tr/ACGTacgt/TGCAtgca/; #complement sequence
	#print "$revseq = this is the reverse complement\n\n";
	$oldpart = substr($sequence, ($best_qstart - 1));
	$newpart = substr($revseq, 0, ($best_subjlength - $best_sstart));
	$extended_seq = $newpart . $oldpart;
    }

    print "$bestID\n\n";
    print "$extended_seq = extension\n\n";

    return $bestdirection;
    return $oldpart;
    return $newpart;
    return $extended_seq;
} #end subroutine
















