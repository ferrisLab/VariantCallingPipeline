#!/bin/bash
#SBATCH --job-name=BAR_bam_diagnostics
#SBATCH --mail-user=baponterolon@tulane.edu
#SBATCH --output=/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/2_1_diagnostics/output/bam_diagnostics_%A_%a.out
#SBATCH --error=/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/2_1_diagnostics/errors/bam_diagnostics_%A_%a.err
#SBATCH --qos=normal
#SBATCH --time=24:00:00
#SBATCH --mem=256000 #Up to 256000, the maximum increases queue time
#SBATCH --nodes=1            #: Number of Nodes
#SBATCH --ntasks-per-node=1  #: Number of Tasks per Node
#SBATCH --cpus-per-task=20   #: Number of threads per task
#SBATCH --array=1-474  # Job array (1-n) when n is number of unique samples that came off the sequencer. 499 total BUT 46 samples in BAR29 missing


### LOAD MODULES ###
module load java-openjdk/1.8.0
module load gatk/4.5.0.0

######################################################
### Diagnostics for Simple_pre_processing_workflow ###
######################################################

echo "Start Job"

### GLOBAL VARIABLES ###
WD="/lustre/project/svanbael/bolivar/Mimulus_sequences/mim3_bioinformatics/ddRAD/3_preprocessing/alignments_untrimmed/"
#PICARD="/share/apps/picard/2.20.7/picard.jar"

### MOVE TO WORKING DIRECTORY ###
cd ${WD}

### ASSIGNING VARIABLES ###
P=$(find ${WD}* -type d \
    | sort \
    | awk -v line=${SLURM_ARRAY_TASK_ID} 'line==NR')

SAMPLE=$(echo $P | cut -d "/" -f 11) #Retrieves sample name
echo ${SAMPLE}


### BAM DIAGNOSTICS ###
### Using new Picard syntax
#java -jar $PICARD ValidateSamFile \
gatk ValidateSamFile \
    -I ${SAMPLE}/${SAMPLE}_markdup.bam \
    -VALIDATION_STRINGENCY STRICT \
    -REFERENCE_SEQUENCE $REF \
    -MODE SUMMARY \


module purge
echo "End Job"