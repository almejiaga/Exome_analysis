!/bin/sh
#pidiendo los archivos de entrada
echo "Please enter your forward filename without extension:"
read filename
echo "the code works if you see a .fastq extension in here ${filename}.fastq"
echo "Please enter your reverse filename2 without extension:"
read filename2
echo "the code works if you see a .fastq extension in here ${filename2}.fastq"
#generando archivos HTML en fastqc
#fastqc ${filename}.fastq.gz ${filename2}.fastq.gz
#alineamiento al genoma de referencia hg19
bwa=bwa
$bwa mem -t 4 -M /home/Proyecto_Tautologia/Software/data/hg19.fa ${filename}.fastq.gz ${filename2}.fastq.gz > ${filename}.sam
echo "ya hice el alineamiento"
#convirtiendo el sam a BAM
samtools=samtools
$samtools view -bh -@ 3 -o ${filename}.bam ${filename}.sam
echo "ya converti el sam en un archivo bam"
#añadiendo los grupos de reads
java -jar /opt/Software/picard/build/libs/picard.jar AddOrReplaceReadGroups I=${filename}.bam O=${filename}-wRG.bam SO=coordinate CREATE_INDEX=true RGID=K00171 RGLB=SureSelectXT RGPL=illumina RGPU=K00171 RGSM=1
#marcando duplicados
java -jar /opt/Software/picard/build/libs/picard.jar MarkDuplicates I=${filename}-wRG.bam O=${filename}-noDups.bam M=1.metrics REMOVE_DUPLICATES=TRUE
#organizando los reads
java -jar /opt/Software/picard/build/libs/picard.jar AddOrReplaceReadGroups I=${filename}-noDups.bam O=${filename}-sorted2.bam SO=coordinate CREATE_INDEX=true RGID=K00171 RGLB=SureSelectXT RGPL=illumina RGPU=K00171 RGSM=360_sample
echo "ya a adi  grupos a los reads, marqué duplicados y organice los reads"
java -jar /opt/Software/picard/build/libs/picard.jarBuildBamIndex INPUT=${filename}-sorted2.bam
echo "ya generé el index del archivo bam"
#recalibrando las bases con GATK
gatk BaseRecalibrator -I ${filename}-sorted2.bam -R /home/learning/estudiantes_gtp/Software/data/hg19.fa --known-sites /home/learning/estudiantes_gtp/Software/data/dbsnp_138.hg19.vcf --known-sites /home/learning/estudiantes_gtp/Software/data/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf -O ${filename}-recal_data.table
#generando un nuevo BAM recalibrado
gatk ApplyBQSR -I ${filename}-sorted2.bam -R /home/learning/estudiantes_gtp/Software/data/hg19.fa --bqsr-recal-file ${filename}-recal_data.table -O ${filename}-BQSR.bam
#generando una posrecal table con las bases ya calibradas
gatk BaseRecalibrator -I ${filename}-BQSR.bam -R /home/learning/estudiantes_gtp/Software/data/hg19.fa --known-sites /home/learning/estudiantes_gtp/Software/data/dbsnp_138.hg19.vcf --known-sites /home/learning/estudiantes_gtp/Software/data/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf -O ${filename}-postRecal_data.table
#generando los gráficos del antes vs el después de la recalibración
gatk AnalyzeCovariates -before ${filename}-recal_data.table -after ${filename}-postRecal_data.table -plots ${filename}-recalibration_plots.pdf
#llamando las variantes con GATK
gatk HaplotypeCaller -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -I ${filename}-BQSR.bam -L /home/learning/estudiantes_gtp/Software/data/S04380219_Covered.bed -O ${filename}-raw_hg19.vcf
#extrayendo los SNPs
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-raw_hg19.vcf --select-type-to-include SNP -O ${filename}-SNPraw_hg19.vcf
#extrayendo los INDELs
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-raw_hg19.vcf  --select-type-to-include INDEL -O ${filename}-INDELraw_hg19.vcf
#marcar las variantes con parametros de calidad para posteriormente filtrar
#snps
gatk VariantFiltration -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-SNPraw_hg19.vcf --filter-expression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0 || SOR > 3.0 || DP < 341" --filter-name "filter1" -O ${filename}-SNPfiltered_hg19.vcf
#indels
gatk VariantFiltration -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-INDELraw_hg19.vcf --filter-expression "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0 || SOR > 10.0 || DP < 341" --filter-name "filter2" -O ${filename}-INDELfiltered_hg19.vcf
#extraer solamente SNPs que pasaron el control de calidad
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-SNPfiltered_hg19.vcf -O ${filename}-SNP-PASS_hg19.vcf --exclude-filtered
#extraer solo INDELS que pasaron el control de calidad
gatk SelectVariants -R /home/learning/estudiantes_gtp/Software/data/hg19.fa -V ${filename}-INDELfiltered_hg19.vcf -O ${filename}-INDEL-PASS_hg19.vcf --exclude-filtered
#comprimir los VCFs de INDEL y SNPs
bgzip -c ${filename}-SNP-PASS_hg19.vcf  > ${filename}-SNP-PASS_hg19.vcf.gz
tabix -p vcf ${filename}-SNP-PASS_hg19.vcf.gz
bgzip -c ${filename}-INDEL-PASS_hg19.vcf  > ${filename}-INDEL-PASS_hg19.vcf.gz
tabix -p vcf ${filename}-INDEL-PASS_hg19.vcf.gz
#concatenar SNPs e INDELS
bcftools concat -a ${filename}-SNP-PASS_hg19.vcf.gz ${filename}-INDEL-PASS_hg19.vcf.gz > ${filename}-final.vcf