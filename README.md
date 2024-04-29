# Exome analysis
Pipeline for variant calling using FASTQ files and for variant annotation and  priorization for causal variant discovery from germline DNA

## Requirements for the analysis
1. FASTQC
2. bwa
3. samtools
4. picard
5. GATK >= 4.0
6. bcftools
7. Annovar

## First step: quality control and variant calling
Run the variantcalling.sh script the following way:

bash variantcalling.sh

It will ask you for the name of each file (forward and reverse) of your vcf file,  $name1.fastq.gz and second one $name2.fastq.gz

You can change the pathway of each software, if they are added to the path, the script will be able to run all of them except picard

## Second step
Variant annotation using Annovar.

You can use the Annotation_annovar.sh script, but you have to download all the databases. In contrast, you can use the online version to upload your vcf file: https://wannovar.wglab.org/

## Filtering and variant priorization
1. Removing common variants (Allele frequency >1%)
2. removing variants with CADD score < 15
3. Check clinvar annotation if available
4. Use phenotype columns to check if they adjust to the phenotype you are studying

## Citation
If you use this pipele for your analysis, please cite the following papers:
1. Arias-Pérez RD, Gallego-Quintero S, Taborda NA, Restrepo JE, Zambrano-Cruz R, Tamayo-Agudelo W, Bermúdez P, Duque C, Arroyave I, Tejada-Moreno JA, Villegas-Lanau A, Mejía-García A, Zapata W, Hernandez JC, Cuartas-Montoya G. Ichthyosis: case report in a Colombian man with genetic alterations in ABCA12 and HRNR genes. BMC Med Genomics. 2021 May 26;14(1):140. doi: 10.1186/s12920-021-00987-y. PMID: 34039366; PMCID: PMC8157432
2. Fajardo-Jiménez MJ, Tejada-Moreno JA, Mejía-García A, Villegas-Lanau A, Zapata-Builes W, Restrepo JE, Cuartas GP, Hernandez JC. Ehlers-Danlos: A Literature Review and Case Report in a Colombian Woman with Multiple Comorbidities. Genes (Basel). 2022 Nov 15;13(11):2118. doi: 10.3390/genes13112118. PMID: 36421793; PMCID: PMC9689997.
