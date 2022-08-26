#!/usr/bin/bash
OUT_DIR=$3
RAW_READS_DIR=$1
REF_GENOME=$2
#########ungiz files
gunzip *.fastq.gz
gunzip *.fa.gz
###Quality controle for all reads
module load fastqc
fastqc $RAW_READS_DIR/*.fastq 
mkdir -p output/qualityControle
mv *.zip output/qualityControle
mv *.html output/qualityControle
#########trim the reads
####run fastp: in1 is the input for the reverse and in2 the input for the forward. 
module load fastp
for infile in $RAW_READS_DIR/*r1_chr5_12_17.fastq
do
   base=$(basename ${infile} r1_chr5_12_17.fastq) 
   fastp --in1 ${infile} --in2 ${base}r1_chr5_12_17.fastq --out1 ${base}r1.trimmed.fastq --out2 ${base}r2.trimmed.fastq -h log.html
done
mkdir -p output/trimmed
mv *.trimmed.fastq output/trimmed
################alignment with BWA
####create directories for results
mkdir  results/sam 
mkdir results/bam
mkdir results/bcf 
module load bwa
module load samtools
######index
bwa index $REF_GENOME
#####################align reference genome
bwa mem -M $REF_GENOME <(cat output/trimmed/*r1*.fastq) <(cat output/trimmed/*r2*.fastq) > results/sam/reads.aligned.sam
###########################convert sam to bam
samtools view -S -b results/sam/reads.aligned.sam > results/bam/reads.aligned.bam
samtools sort -o results/bam/reads.aligned.sorted.bam results/bam/reads.aligned.bam 
samtools flagstat results/bam/reads.aligned.sorted.bam
#################
#freebayes
module load  python
module load vcflib
module load freebayes
freebayes -f $REF_GENOME  results/bam/reads.aligned.sorted.bam > $OUT_DIR/reads.vcf 
