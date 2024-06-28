#!/bin/bash
#SBATCH --job-name=BAR_bam_reassignment
#SBATCH --mail-user=baponterolon@tulane.edu
#SBATCH --output=/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/2_2_reassignment/output/bam_reassigned_%A_%a.out
#SBATCH --error=/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/2_2_reassignment/errors/bam_reassigned_%A_%a.err
#SBATCH --qos=normal
#SBATCH --time=0-24:00:00
#SBATCH --mem=256000 #Up to 256000, the maximum increases queue time
#SBATCH --nodes=1            #: Number of Nodes
#SBATCH --ntasks-per-node=1  #: Number of Tasks per Node
#SBATCH --cpus-per-task=20   #: Number of threads per task
#SBATCH --array=1-475  # Job array (1-n) when n is number of unique samples that came off the sequencer. 499 total BUT 46 samples in BAR29 missing


### LOAD MODULES ###
module load java-openjdk
module load gatk/4.5.0.0

###################################################################
### Adding or replacing read group information in the bam files ###
###################################################################

echo "Start Job"

#### GLOBAL VARIABLES ###
WD="/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/3_preprocessing/alignments_untrimmed/"
REF="/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/MimulusGuttatus_reference/MguttatusTOL_551_v5.0.fa" # Path to reference genome
THREADS=20 # Number of threads to use
TMPDIR="/lustre/project/svanbael/TMPDIR" # Designated storage folders for temporary files (should be empty at end)
#PICARD="/share/apps/picard/2.20.7/picard.jar" # Path to picard

### CHANGE DIRECTORY TO WHERE THE BAM FILES ARE LOCATED ###
cd ${WD}

### ASSIGNING VARIABLES ###
P=$(find ${WD}* -type d \
    | sort \
    | awk -v line=${SLURM_ARRAY_TASK_ID} 'line==NR')

SAMPLE=$(echo $P | cut -d "/" -f 11) #Retrieves sample name
HEADER=$(echo $P | cut -d "/" -f 11)
echo ${SAMPLE}


### VARIABLES FOR READ GROUP INFORMATION ###
RGID=${SEQID} # Read group identifier/project name. In this case it is the same as $SEQID. 
              # It can be called variable by just writing "bar_mim3", for example.
RGLB="8850_240112B9" # Library name (could be anything). Using the order # and run date.
RGPL="ILLUMINA" # Sequencing platform
RGPM="NextSeqX" # Platform modeLl
LANE="_L8" # Lane number
RGPU=${RGPM}${LANE} # Identifier for the platform unit (run barcode, flowcell barcode, etc.)

# This tool enables the user to either replace all read groups in the input file or \
# to add a read group to each read that does not have a read group. Which could be the source of errors.
echo "Adding or replacing read group information"

#java -jar $PICARD AddOrReplaceReadGroups \
gatk AddOrReplaceReadGroups \
    -I ${HEADER}/${SAMPLE}_markdup.bam \
    -O ${HEADER}/${SAMPLE}_markdup_rrg.bam \
    -RGID $RGID \
    -RGLB $RGLB \
    -RGPL $RGPL \
    -RGPU $RGPU \
    -RGSM ${SAMPLE} \
    -VALIDATION_STRINGENCY LENIENT


module purge
echo "End Job"

