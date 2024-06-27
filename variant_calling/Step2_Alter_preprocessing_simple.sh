#!/bin/bash
#SBATCH --job-name=BAR_preproces
#SBATCH --mail-user=baponterolon@tulane.edu
#SBATCH --mail-type=ALL # Valid values: BEGIN, END, FAIL, REQUEUE and ALL.
#SBATCH --output=/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/3_preprocessing/preprocessingout/pre-processing_%A_%a.out
#SBATCH --error=/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/3_preprocessing/preprocessingerror/pre-processing_%A_%a.err
#SBATCH --qos=normal
#SBATCH --time=24:00:00
#SBATCH --mem=256000 #Up to 256000, the maximum increases queue time
#SBATCH --nodes=1            #: Number of Nodes
#SBATCH --ntasks-per-node=1  #: Number of Tasks per Node
#SBATCH --cpus-per-task=20   #: Number of threads per task
#SBATCH --array=1-474  # Job array (1-n) when n is number of unique samples that came off the sequencer. 499 total


### LOAD MODULES ###
module load bwa/0.7.17 
module load samtools/1.16.1
module load java-openjdk/1.8.0

#####################################################################
<<Simple_Alter_pre_processing_workflow
SIMPLE WORKFLOW- samples not split across lanes
Written in spring 2022 by Natalie Gonzalez

Modified by BAR 2024-06-03

Minor changes include:
    - Using samtools v.1.16.1 as opposed to v.1.10
    - bwa/0.7.17 as opposed to bwa
    - java-openjdk/1.8.0 as opposed to java-openjdk

Major changes include:
    - Creating alternative pipeline based on @bergcollete's GitHub: YNP_GWAS/scripts/YNP4alignment.sh 
    for alignment with bwa, samtools, and picard for read group information.


This script is designed to prepare samples for GATK varient calling. 
It begins with sequence files in seqdata.fq.gz or seqdata.fq format.

As opposed to the Legacy pipeline, which assigns read group information
with bwa, this one uses bwa mem for alignment, samtools for quality control, 
and picard for read group information. 

The workflow is as follows:
    -Perform the alignment with bwa -mem
    -Quality filter and sort sam, making a bam file
    -Add read groups

It results in the conversion of .sam files to .bam files. The resulting file will
be an aligned paired end and sorted bam file.

Output file: ${SAMPLE}_aln_pe_fm_sorted.bam

NOTE: This script makes use of an array and by nature of a job array not all .bam
files will be generated at the same time. Make sure the entire job is done running
before moving forward. You can check on a job by using the "squeue" command in the 
terminal.
 
For second half- The workflow I followed uses the following documentation:
https://eriqande.github.io/eca-bioinf-handbook/alignment-of-sequence-data-to-a-reference-genome-and-associated-steps.html
In summary, the steps taken should be asigning read groups, aligning with bwa, and
processing with samtools


Input file:  ${SAMPLE}_aln_pe_sorted.bam
Output files:${SAMPLE}_merged.bam
                ${SAMPLE}_markdup.bam
                ${SAMPLE}_markdup.bam.bai
                ${SAMPLE}_markdup.bam.flagstat.txt

Simple_Alter_pre_processing_workflow
#####################################################################

echo "Start Job"

#### GLOBAL VARIABLES ###
WD="/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/2_fastQC"
SEQID="bar_mim3" # Read group identifier/Project name and date for bam header
REF="/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/MimulusGuttatus_reference/MguttatusTOL_551_v5.0.fa" # Path to reference genome
THREADS=20 # Number of threads to use
TMPDIR="/lustre/project/svanbael/TMPDIR" # Designated storage folders for temporary files (should be empty at end)
PICARD="/share/apps/picard/2.20.7/picard.jar" # Path to picard
OUTPUT_DIR="/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/3_preprocessing/alignments_untrimmed/" # Path to directory where alignment files will be stored

### NAVIGATING TO THE DIRECTORY CONTAINING THE FASTQ FILES ###
### WD should be the directory containing the fastq files ###
cd ${WD}

### RETRIEVING SAMPLE NAMES AND ASSIGNING AS VARIABLES ###
# Array 1-n represents n number of samples and SLURM_ARRAY_TASK_ID represents elements in that array.
# The following line allows us to link the elements of the array with the FW and RV read files (R1/R2).
# The sort step should sort samples alphanumerically.
# Note: the find command searches recursively, grep command selects either read 1 or 2.

FOR_EXT="1.fq.gz" #forward read extension
REV_EXT="2.fq.gz" #reverse read extension

R1=$(find ${WD} \
    | grep $FOR_EXT \
    | sort \
    | awk -v line=${SLURM_ARRAY_TASK_ID} 'line==NR')
R2=$(find ${WD} \
    | grep $REV_EXT\
    | sort \
    | awk -v line=${SLURM_ARRAY_TASK_ID} 'line==NR')


echo ${R1}
echo ${R2}
echo ${SLURM_ARRAY_TASK_ID}

# Sample prefix from the R1/R2 files, is in the sample_names.list (ex: KGF_02.._L3)
# This part changes based on the naming system. The user will have to modify this as needed
# The first "SAMPLE" command takes the file name in the xth field of the "/" delimiter, so you want to make sure that you have the full file path written and it is in that position. 
# So if you input "/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/2_fastQC/OPN_11_2_F2WY.2.fq.gz" you get "OPN_11_2_F2WY" for both sample and header in this code. 
SAMPLE=$(echo $R1 | cut -d "/" -f 10 | cut -d "." -f 1) # Retrieves first element before "."
HEADER=$(echo $R1 | cut -d "/" -f 10 | cut -d "." -f 1) # Retrieves first element before "." 

echo ${SAMPLE}
echo ${HEADER}

####################################################################################################
### Alternative Pipeline for Alignment with BWA, SAMTOOLS, and PICARD for Read Group Information ###
####################################################################################################

##################################################################################################
### Allignment with BWA, quality control with SAMTOOLS, and read group information with PICARD ###
##################################################################################################
# Adapted from @bergcollete's GitHub: YNP_GWAS/scripts/YNP4alignment.sh 

### VARIABLES FOR READ GROUP INFORMATION ###
RGID=${SEQID} # Read group identifier/project name. In this case it is the same as $SEQID. 
              # It can be called variable by just writing "bar_mim3", for example.
RGLB="lib1" # Library name (could be anything)
RGPL="ILLUMINA" # Sequencing platform
RGPU="unit1" # Generic identifier for the platform unit

### SETTING WORKING DIRECTORY WHERE BWA OUTPUTS WILL GO ###
# Make alignments_untrimmed folder
cd ${OUTPUT_DIR}
mkdir ${HEADER}  #makes a directory for each biological sample.


### Map reads to the genome AND Quality filter and sort sam, making a bam file
echo "Aligning bwa mem quality filtering, and sorting for ${SAMPLE}"

# bwa mem -R '@RG\tID:'${SEQID}'\tSM:'${SAMPLE}'\tLB:lib1' -t ${THREADS} ${REF} ${R1} ${R2} | \
bwa mem -t ${THREADS} ${REF} ${R1} ${R2} | \
samtools view -hb -@ ${THREADS} - | \
samtools sort -n -T $TMPDIR -@ ${THREADS} - -o ${HEADER}/${SAMPLE}_aln_pe_sorted.bam | \
samtools fixmate -rm -@ ${THREADS} ${HEADER}/${SAMPLE}_aln_pe_sorted.bam - | \
samtools sort -T $TMPDIR -@ ${THREADS} - -o ${HEADER}/${SAMPLE}_aln_pe_fm_sorted.bam

### Add read groups
echo "Adding read group information to ${SAMPLE}"

java -jar $PICARD AddOrReplaceReadGroups \
    I=${HEADER}/${SAMPLE}_aln_pe_fm_sorted.bam \
    O=${HEADER}/${SAMPLE}_aln_pe_fm_rg_sorted.bam \
    RGSM=${SAMPLE} \
    RGID=${SEQID} \
    RGLB=$RGLB \
    RGPL=$RPGL \
    RGPU=$RGPU \
    VALIDATION_STRINGENCY=LENIENT # adds read groups

echo "End Alignment"

### MARK AND REMOVE DUPLICATE READS ###
echo "Marking and removing duplicate reads"

# java -jar $PICARD MarkDuplicates \
#      I=${HEADER}/${SAMPLE}_aln_pe_fm_rg_sorted.bam \
#      O=${HEADER}/${SAMPLE}_markdup.bam \
#      METRICS_FILE=${HEADER}/${SAMPLE}_dup_metrics.txt \
#      ASSUME_SORTED=true \
#      REMOVE_DUPLICATES=true \
#      VALIDATION_STRINGENCY=LENIENT \
#      TMP_DIR=$TMPDIR

# echo "End Marking and removing duplicate reads"

# ### INDEXING THE BAM FILE & FLAG STATS##
# echo "Indexing the bam file and calculating flag stats"

# samtools index -@ ${THREADS} ${HEADER}/${SAMPLE}_markdup.bam

# echo "End Indexing"

# ### LOOKING AT ALIGNMENT AGAIN ###
# ### `flagstat` counts the number of alignments for each FLAG type and calculates and prints statistics
# echo "Calculating flag stats"
# samtools flagstat -@ ${THREADS} ${HEADER}/${SAMPLE}_markdup.bam \
#    > ${HEADER}/${SAMPLE}_markdup.bam.flagstat.txt

echo "End Flag Stats"

module purge
echo "End Job"
###########################################################################################################
### END OF ALTERNATIVE PIPELINE FOR ALIGNMENT WITH BWA, SAMTOOLS, AND PICARD FOR READ GROUP INFORMATION ###
###########################################################################################################
