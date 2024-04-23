#conver the VCF file to the standard annovar input
convert2annovar.pl -includeinfo -allsample -withfreq -format vcf4 007_filtrado.vcf > 007_filtrado.avinput
#annotating the variants and generating a txt output csv file
table_annovar.pl 007_filtrado.avinput humandb/ -buildver hg19 -protocol refGene,cytoBand,genomicSuperDups,esp6500siv2_all,ALL.sites.2015_08,exac03,avsnp147,dbnsfp30a -operation g,r,r,f,f,f,f,f -nastring NA
