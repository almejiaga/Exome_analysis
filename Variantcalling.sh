!/bin/sh
#asking for the prefix of the input file 
echo "Please enter your forward filename without extension:"
read filename
echo "the code works if you see a .fastq extension in here ${filename}.fastq"
echo "Please enter your reverse filename2 without extension:"
read filename2
echo "the code works if you see a .fastq extension in here ${filename2}.fastq"
#generate quality control html files from  pairedmFASTQ files
#fastqc ${filename}.fastq.gz ${filename2}.fastq.gz
#alignment to the reference genome hg19
bwa=bwa
$bwa mem -t 4 -M hg19.fa ${filename}.fastq.gz ${filename2}.fastq.gz > ${filename}.sam
echo "Alignment is done"
#Converting from sam to BAM with samtools
samtools=samtools
$samtools view -bh -@ 3 -o ${filename}.bam ${filename}.sam
echo "sam converted to Bam succesfully"
#adding read groups (required for running GATK)
java -jar /opt/Software/picard/build/libs/picard.jar AddOrReplaceReadGroups I=${filename}.bam O=${filename}-wRG.bam SO=coordinate CREATE_INDEX=true RGID=K00171 RGLB=SureSelectXT RGPL=illumina RGPU=K00171 RGSM=1
#flagging duplicates
java -jar /opt/Software/picard/build/libs/picard.jar MarkDuplicates I=${filename}-wRG.bam O=${filename}-noDups.bam M=1.metrics REMOVE_DUPLICATES=TRUE
#sorting reads
java -jar /opt/Software/picard/build/libs/picard.jar AddOrReplaceReadGroups I=${filename}-noDups.bam O=${filename}-sorted2.bam SO=coordinate CREATE_INDEX=true RGID=K00171 RGLB=SureSelectXT RGPL=illumina RGPU=K00171 RGSM=360_sample
echo "ya a adi  grupos a los reads, marqué duplicados y organice los reads"
echo "reads are grouped, duplicates are flagged and reads are sorted"
java -jar /opt/Software/picard/build/libs/picard.jarBuildBamIndex INPUT=${filename}-sorted2.bam
echo "Bam has been indexed"
#Base recalibration using GATK
gatk BaseRecalibrator -I ${filename}-sorted2.bam -R /home/learning/estudiantes_gtp/Software/data/hg19.fa --known-sites /home/learning/estudiantes_gtp/Software/data/dbsnp_138.hg19.vcf --known-sites /home/learning/estudiantes_gtp/Software/data/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf -O ${filename}-recal_data.table
#generating a recalibrated BAM
gatk ApplyBQSR -I ${filename}-sorted2.bam -R /home/learning/estudiantes_gtp/Software/data/hg19.fa --bqsr-recal-file ${filename}-recal_data.table -O ${filename}-BQSR.bam
#generating posrecal table with calibrated bases
gatk BaseRecalibrator -I ${filename}-BQSR.bam -R /home/learning/estudiantes_gtp/Software/data/hg19.fa --known-sites /home/learning/estudiantes_gtp/Software/data/dbsnp_138.hg19.vcf --known-sites /home/learning/estudiantes_gtp/Software/data/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf -O ${filename}-postRecal_data.table
#generating plots before and after recalibration
gatk AnalyzeCovariates -before ${filename}-recal_data.table -after ${filename}-postRecal_data.table -plots ${filename}-recalibration_plots.pdf
#variant calling with GATK
gatk HaplotypeCaller -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -I ${filename}-BQSR.bam -L /home/learning/estudiantes_gtp/Software/data/S04380219_Covered.bed -O ${filename}-raw_hg19.vcf
#extracting SNPs
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-raw_hg19.vcf --select-type-to-include SNP -O ${filename}-SNPraw_hg19.vcf
#extracting INDELs
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-raw_hg19.vcf  --select-type-to-include INDEL -O ${filename}-INDELraw_hg19.vcf
#flaggin variants with PASS according to the filters proposed with hard filtering
# for snps
gatk VariantFiltration -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-SNPraw_hg19.vcf --filter-expression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0 || SOR > 3.0 || DP < 341" --filter-name "filter1" -O ${filename}-SNPfiltered_hg19.vcf
#for indels
gatk VariantFiltration -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-INDELraw_hg19.vcf --filter-expression "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0 || SOR > 10.0 || DP < 341" --filter-name "filter2" -O ${filename}-INDELfiltered_hg19.vcf
#extraer only SNPS that passed the quality filter
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-SNPfiltered_hg19.vcf -O ${filename}-SNP-PASS_hg19.vcf --exclude-filtered
#extraer only INDELS that passed quality filter
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-INDELfiltered_hg19.vcf -O ${filename}-INDEL-PASS_hg19.vcf --exclude-filtered
#compress VCFs of INDEL and SNPs to later merge with bcftools
bgzip -c ${filename}-SNP-PASS_hg19.vcf  > ${filename}-SNP-PASS_hg19.vcf.gz
tabix -p vcf ${filename}-SNP-PASS_hg19.vcf.gz
bgzip -c ${filename}-INDEL-PASS_hg19.vcf  > ${filename}-INDEL-PASS_hg19.vcf.gz
tabix -p vcf ${filename}-INDEL-PASS_hg19.vcf.gz
#concat SNPs and INDELS
bcftools concat -a ${filename}-SNP-PASS_hg19.vcf.gz ${filename}-INDEL-PASS_hg19.vcf.gz > ${filename}-final.vcf
