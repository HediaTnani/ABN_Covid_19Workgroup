#!/bin/bash

echo "hello world"

# creating a symbolic link
#ln -s /home/tdo/Mapping/ERR*  ./output/


# indexing the reference sequence
echo "indexing the ref seq"
bwa index /home/course46/Data/Mapping/Paired/Covid-19.reference.fasta 

# Mapping
echo " I am doing the mapping"

for reads in `ls *fastq.gz | sed -e s/_[12].fastq.gz// | sort | uniq`

do bwa mem -R "@RG\tID:$reads\tSM:$reads" /home/course46/Data/Mapping/Paired/Covid-19.reference.fasta ${reads}_1.fastq.gz ${reads}_2.fastq.gz > ${reads}.sam

echo "converting sam to bam and sorting"
samtools view -Sb ${reads}.sam | samtools sort - > ${reads}.sorted.bam
done

echo "indexing the sorted bam files"

for z in `ls *sorted.bam`

do samtools index ${z}

done

echo " Variant calling using freebayes"
for file in `ls *sorted.bam`

do freebayes -f /home/course46/Data/Mapping/Paired/Covid-19.reference.fasta --genotype-qualities ${file} >freeB${file}.vcf

done


# compressing vcf files

for z in `ls *.vcf`; do bgzip ${z}; done

echo "I am indexing the vcf files"

#indexing the vcf files

for x in `ls *.vcf.gz`

do  bcftools index ${x} # alternatively use tabix


done

# Merging the individual vcf files

bcftools merge *.vcf.gz -Ov -o Merged.vcf


echo "I am filtering snps from merged vcf file"
# Filtering snps on the bases pf GQ>=20 and DP>=20

for y in `ls *.vcf`

do bcftools filter -i'GQ>=20 && INFO/DP>=20' ${y} > filter${y}

done


echo "Phylogenetic analysis"
# Extracting snps in form a fasta file
vk phylo fasta filterMerged.vcf > Merged.fasta
# Constructing a phylogenetic tree from the snps
vk phylo tree upgma filterMerged.vcf  > Treefile.newick


echo "Thank you God, its a success"
