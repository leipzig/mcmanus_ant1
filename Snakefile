import glob
from snakemake.utils import R
import re
import socket
from time import gmtime, strftime

WEBSITE = "user@server:/pathtowebdir/"
REFDIR = "refs/Mus_musculus/Ensembl/GRCm38/"
TMPDIR = "/tmp/"
FASTAREF = REFDIR + "Sequence/WholeGenomeFasta/genome.fa"
STARREFDIR = REFDIR + "star/"
CHRNAME = STARREFDIR + "chrName.txt"
GTFFILE = REFDIR + "Annotation/Genes/genes.gtf"
PRIM_GTF = REFDIR + "Annotation/Genes/primary_genes.gtf"
MASKFILE = REFDIR + "Annotation/mask.gtf"
RRNA = REFDIR + "Annotation/GRCm38_rRNA.list"

S3_LINK = "https://s3.amazonaws.com/inx.wallacelab.ant1rnaseq"
S3_BUCKET = "s3://inx.wallacelab.ant1rnaseq"
S3_PROFILE = "leipzig"


##### TOOLS #####
CUTADAPT = "cutadapt"
BEDTOOLS = "bedtools"
ALIGN = "novoalign"
INDEX = "novoindex"
SORT = "novosort"
TOOLDIR = "tools"
RNASEQC = TOOLDIR + "/RNA-SeQC_v1.1.8.jar"
STAR = "star"
SAMTOOLS = "samtools"
CUFF = "cufflinks"
CUFFMERGE = "cuffmerge"
CUFFDIFF = "cuffdiff"
EXPR = "express"

# ANT1 evens
MUSCLE_KO = "IonXpressRNA_002.R_2013_11_26_13_55_09_user_1PR-8-RNA-Seq_whole_transcriptome IonXpressRNA_004.R_2013_11_26_20_48_53_user_1PR-9-RNA-Seq_whole_transcriptome IonXpressRNA_006.R_2013_12_04_09_37_33_1PR-10-RNA-Seq_whole_transcriptome_76303 IonXpressRNA_008.R_2013_12_06_12_45_12_user_1PR-11-RNA-Seq_whole_transcriptome"

# B6ME odds
MUSCLE_WT = "IonXpressRNA_001.R_2013_11_26_13_55_09_user_1PR-8-RNA-Seq_whole_transcriptome IonXpressRNA_003.R_2013_11_26_20_48_53_user_1PR-9-RNA-Seq_whole_transcriptome IonXpressRNA_005.R_2013_12_04_09_37_33_1PR-10-RNA-Seq_whole_transcriptome_76303 IonXpressRNA_007.R_2013_12_06_12_45_12_user_1PR-11-RNA-Seq_whole_transcriptome"

# ANT1 evens
HEART_KO = "IonXpressRNA_010.R_2013_12_19_16_11_21_user_1PR-13-RNA-Seq_whole_transcriptome IonXpressRNA_012.R_2013_12_18_20_25_40_user_1PR-12-RNA-Seq_whole_transcriptome IonXpressRNA_014.R_2013_12_20_12_50_23_user_1PR-14-RNA-Seq_whole_transcriptome IonXpressRNA_016.R_2013_12_21_20_34_59_user_1PR-15-RNA-Seq_whole_transcriptome"

# B6ME odds
HEART_WT = "IonXpressRNA_009.R_2013_12_19_16_11_21_user_1PR-13-RNA-Seq_whole_transcriptome IonXpressRNA_011.R_2013_12_18_20_25_40_user_1PR-12-RNA-Seq_whole_transcriptome IonXpressRNA_013.R_2013_12_20_12_50_23_user_1PR-14-RNA-Seq_whole_transcriptome IonXpressRNA_015.R_2013_12_21_20_34_59_user_1PR-15-RNA-Seq_whole_transcriptome"

GROUP_NAMES = 'MUSCLE_KO MUSCLE_WT HEART_KO HEART_WT'.split()
SAMPLES = ' '.join([MUSCLE_KO, MUSCLE_WT, HEART_KO, HEART_WT]).split()
PRETTY_NAMES = ['{0}_{1}'.format(sample, i)
                for sample in GROUP_NAMES for i in range(1, 5)]

DIRS = ['mapped/', 'counts/', 'cufflinks/']
MAPPED = ['mapped/' + f + '.bam' for f in SAMPLES]
GENES = ['MT-ND1','MT-ND6','MT-ND3','MT-CYTB']
GENEREADS = ['gene_reads/' + f + '.' + g + '.fa' for f in SAMPLES for g in GENES]
GATKED = ['mapped/' + f + '.sorted.gatk.bam.bai' for f in SAMPLES]
COUNTS = ['counts/' + f + '.tsv' for f in SAMPLES]
CUFFED = ['cufflinks/' + f + '/transcripts.gtf' for f in SAMPLES]
EXPRED = ['express/reports/' + f + '/results.xprs' for f in SAMPLES]
STARLOGS = 'starlogs.parsed.txt'
SAMPLEFILE = "samplefile.rnaseqc.txt"
RNASEQC_DIR = "RNASEQC_DIR/"
RNASEQC_INDEX = RNASEQC_DIR + "index.html"
BIGWIGS = ['tracks/' + f + '.bw' for f in SAMPLES]
BIGWIG_NAMES = [ f + '.bw' for f in SAMPLES]
QCED = ['fastqc/' + f + '.trimmed_fastqc.zip' for f in SAMPLES]
ERCC = ['ercc/' + f + '.idxstats' for f in SAMPLES]
GO_DOMAINS = ['biological_process', 'cellular_component', 'molecular_function']
GAGE_GO_FILES = ['GAGE/GO.' + tissue + '.ant1.' + domain + '.' + direction + '.html' for tissue in ['heart', 'muscle']
                 for domain in GO_DOMAINS for direction in ['up', 'down']]
GAGE_GO_CSV_FILES = ['GAGE/GO.' + tissue + '.ant1.' + domain + '.' + direction + '.csv' for tissue in ['heart', 'muscle']
                 for domain in GO_DOMAINS for direction in ['up', 'down']]
GAGE_KEGG_FILES = ['GAGE/KEGG.' + tissue +
                   '.ant1.signaling_or_metabolism_pathways.both.csv' for tissue in ['heart', 'muscle']]
GAGE_FILES = GAGE_GO_FILES + GAGE_GO_CSV_FILES + GAGE_KEGG_FILES

rule all:
    input:
        DIRS, CHRNAME, MAPPED, CUFFED, COUNTS, GATKED, RNASEQC_INDEX, STARLOGS, QCED, BIGWIGS, GAGE_FILES

rule gagefiles:
    input:
        GAGE_FILES

rule genereads:
    input:
        GENEREADS

rule dirs:
    output:
        DIRS
    shell:
        "mkdir -p " + ' '.join(DIRS)

rule testdir:
    shell:
        "pwd >> testdir"

##### CLEAN #####
rule clean:
    shell:
        "rm [0-9]*.snakemake-job*"

##### TRIMMING #####
# cutadapt will auto-gz if .gz is in the output name
rule trim:
    input:
        "{sample}.fastq"
    output:
        "{sample}.trimmed.fastq.gz"
    threads:
        1
    shell:
        "{CUTADAPT} -m 16 -b GGCCAAGGCG -o {output} {input}"

##### ALIGNMENT #####
rule starindex:
    input:
        ref = FASTAREF, starref = STARREFDIR,
    output:
        CHRNAME
    shell:
        "{STAR} --limitGenomeGenerateRAM 54760833024 --runMode genomeGenerate --genomeDir {input.starref} --genomeFastaFiles {input.ref}"

rule map:
    input:
        sample = "raw/{sample}.trimmed.fastq.gz", starref = STARREFDIR, gtf = GTFFILE
    output:
        temp("mapped/{sample}.sam")
    threads:
        24
    shell:
        """
        {STAR} --genomeDir {input.starref} --outFileNamePrefix {wildcards.sample}_ --readFilesIn {input.sample} --runThreadN 24 --genomeLoad NoSharedMemory --outSAMattributes All --outSAMstrandField intronMotif --sjdbGTFfile {input.gtf}
        mv {wildcards.sample}_Aligned.out.sam {output}
        mv {wildcards.sample}_Log.final.out {wildcards.sample}_Log.out {wildcards.sample}_Log.progress.out {wildcards.sample}_SJ.out.tab starlogs
        """

# this is for the table in the diffExp report
rule parselogs:
    input:
        expand('starlogs/{sample}_Log.final.out', sample=SAMPLES)
    output:
        "starlogs.parsed.txt"
    run:
        filename_p = re.compile('starlogs\/(\S+)_Log.final.out')
        input_reads_p = re.compile('Number of input reads\s+\|\s+(.*)')
        unique_reads_p = re.compile('Uniquely mapped reads %\s+\|\s+(.*)')
        multiple_hits_p = re.compile(
            '% of reads mapped to multiple loci\s+\|\s+(.*)')
        input_reads = ''
        unique_reads = ''
        multiple_hits = ''
        with open(output[0], 'w') as outfile:
            outfile.write(
                'sample\tNumber of input reads\tUniquely mapped reads %\t% of reads mapped to multiple loci\n')
            for samplefilename in input:
                sample = filename_p.search(samplefilename).group(1)
                with open(samplefilename, 'r') as file:

                    for line in file:
                        if input_reads_p.search(line):
                            input_reads = input_reads_p.search(line).group(1)
                        elif unique_reads_p.search(line):
                            unique_reads = unique_reads_p.search(line).group(1)
                        elif multiple_hits_p.search(line):
                            multiple_hits = multiple_hits_p.search(
                                line).group(1)
                outfile.write('{0}\t{1}\t{2}\t{3}\n'.format(
                    sample, input_reads, unique_reads, multiple_hits))


# novosort can index
rule sortbam:
    input:
        "{sample}.bam"
    output:
        bam = "{sample}.sorted.bam", bai = "{sample}.sorted.bam.bai"
    threads:
        24
    shell:
        "{SORT} -t {TMPDIR} -s -i -o {output.bam} {input}"

# if you ask for a sorted.bam don't look for a sorted.sam
# ruleorder: sortbam > samtobam
rule samtobam:
    input:
        "{sample}.sam"
    output:
        "{sample}.bam"
    threads:
        1
    shell:
        "{SAMTOOLS} view -bS {input} > {output}"

rule getbed:
     output:
        "{gene}.bed"
     shell:
        """curl -s http://rest.ensembl.org/lookup/symbol/mus_musculus/{wildcards.gene}?content-type=application/json | ./jq-linux64 -r '.| [.seq_region_name, (.start|tostring), (.end|tostring)] | join("\t")' > {output}"""

# extract reads mapping to genes of interest
# one-liner c/o Eric Lim
rule readsfrombamgene:
    input:
        bam = "mapped/{sample}.sorted.bam", bed = "{gene}.bed"
    output:
        "gene_reads/{sample}.{gene}.fa"
    shell:
        """
cat {input.bed} | {BEDTOOLS}/bedtools intersect -abam {input.bam} -b stdin | {SAMTOOLS} view - | grep -v ^@ | awk '{{print ">"$1"\\n"$10}}' > {output}
        """

#### ERCC #####
rule ERCCnix:
    output:
        "refs/ERCC92.nix"
    input:
        "refs/ERCC92.fa"
    shell:
        "{INDEX} {output} {input}"

rule ERCCbam:
    input:
        fastq = "raw/{sample}.trimmed.fastq.gz", ref = "refs/ERCC92.nix"
    output:
        temp("ercc/{sample}.bam")
    shell:
        "{ALIGN} -d {input.ref} -f {input.fastq} -o SAM | {SAMTOOLS} view -bS - > {output}"

rule idxstats:
    input:
        "ercc/{sample}.sorted.bam"
    output:
        "ercc/{sample}.idxstats"
    shell:
        "{SAMTOOLS} idxstats {input} > {output}"

rule idxsummary:
    output:
        "ercc.counts"
    input:
        expand('ercc/{sample}.idxstats', sample=SAMPLES)
    shell:
        """
        grep '^\*' {input} | cut -f1,4 | sed -e 's/\.idxstats:\*//' | sed -e 's/ercc\///'> ercc.counts
        """

#### QC #####
rule fastqc:
    input:
        "raw/{sample}.trimmed.fastq.gz"
    output:
        "fastqc/{sample}.trimmed_fastqc.zip"
    shell:
        "{TOOLDIR}/FastQC/fastqc -o fastqc {input}"

rule AddOrReplaceReadGroups:
    input:
        "{sample}.sorted.bam"
    output:
        "{sample}.sorted.gatk.bam"
    shell:
        "AddOrReplaceReadGroups INPUT= {input} OUTPUT= {output} RGID= {wildcards.sample} LB= {wildcards.sample} RGPL= ionproton RGPU= martin RGSM= {wildcards.sample}"

rule index:
    input:
        "{sample}.sorted.gatk.bam"
    output:
        "{sample}.sorted.gatk.bam.bai"
    shell:
        "BuildBamIndex INPUT= {input} OUTPUT= {output}"

rule dict:
    input:
        "{ref}.fa"
    output:
        "{ref}.dict"
    shell:
        "CreateSequenceDictionary REFERENCE= {input} OUTPUT= {output}"

rule fetchRNASEQC:
     output: RNASEQC
     params: tooldir = TOOLDIR
     shell:
        """
        mkdir -p {params.tooldir}
        curl http://www.broadinstitute.org/cancer/cga/tools/rnaseqc/RNA-SeQC_v1.1.8.jar > {output}"
        """

# samplefile.rnaseqc.txt was made by hand so sue me
rule rnaseqc:
    input:
        sample = SAMPLEFILE, gatked = GATKED, rnaseqc = RNASEQC, rnaseqc_dir = RNASEQC_DIR, ref = FASTAREF, gtf = PRIM_GTF, rna = RRNA
    output:
        RNASEQC_INDEX
    shell:
        "java -jar {input.rnaseqc} -o {input.rnaseqc_dir} -r {input.ref} -s {input.sample} -t {input.gtf} -rRNA {input.rna}"

##### TX Quantification: Cufflinks #####
rule mask:
    input:
        gtf = GTFFILE
    output:
        MASKFILE
    shell:
        "grep -P 'rRNA|tRNA|MT\t' {input.gtf} > {MASKFILE}"

rule cufflinks:
    input:
        bam = "mapped/{sample}.sorted.bam", gtf = GTFFILE, mask = MASKFILE
    output:
        gtf = "cufflinks/{sample}/transcripts.gtf", iso = "cufflinks/{sample}/isoforms.fpkm_tracking", genes = "cufflinks/{sample}/genes.fpkm_tracking"
    threads:
        8
    shell:
        """
        mkdir -p cufflinks/{wildcards.sample}
        {CUFF} -p 8 -g {input.gtf} -M {input.mask} --max-bundle-length 8000000 --multi-read-correct --library-type=fr-secondstrand --output-dir cufflinks/{wildcards.sample} {input.bam}
        """

rule cuffreport:
    input:
        CUFFED
    output:
        "assembly_list.txt"
    run:
        with open(output[0], 'w') as outfile:
            for f in CUFFED:
                outfile.write('{}\n'.format(f))

rule cuffmerge:
    input:
        "assembly_list.txt", gtf = GTFFILE, ref = FASTAREF
    output:
        "cufflinks/merged.gtf"
    shell:
        """
         {CUFFMERGE} -o cufflinks -g {input.gtf} -s {input.ref} -p 16 {input}
        """
MUSCLE_KO_BAMS = ','.join(
    ['mapped/{0}.sorted.bam'.format(f) for f in MUSCLE_KO.split()])
MUSCLE_WT_BAMS = ','.join(
    ['mapped/{0}.sorted.bam'.format(f) for f in MUSCLE_WT.split()])
HEART_KO_BAMS = ','.join(
    ['mapped/{0}.sorted.bam'.format(f) for f in HEART_KO.split()])
HEART_WT_BAMS = ','.join(
    ['mapped/{0}.sorted.bam'.format(f) for f in HEART_WT.split()])

rule cuffdiff:
    input:
        gtf = "cufflinks/merged.gtf", mask = MASKFILE, samples = expand("mapped/{sample}.sorted.bam", sample=SAMPLES)
    output:
        'cufflinks/cuffdiff/isoforms.fpkm_tracking'
    shell:
        """
        {CUFFDIFF} -p 16 -o cufflinks/cuffdiff -M {input.mask} {input.gtf} {MUSCLE_KO_BAMS} {MUSCLE_WT_BAMS} {HEART_KO_BAMS} {HEART_WT_BAMS} 
        """

#####  TX Quantification: Express  #####
CDNA = REFDIR + "Sequence/Transcripts/Mus_musculus.GRCm38.74.cdna.all"
rule txIndex:
    input:
        CDNA + '.fa'
    output:
        CDNA + '.nix'
    shell:
        "{INDEX} {output} {input}"

rule expressbam:
    input:
        fq = "raw/{sample}.trimmed.fastq.gz", ref = CDNA + '.nix'
    output:
        "express/bams/{sample}.sam"
    log:
        "logs/express/{sample}.log"
    shell:
        "{ALIGN} -d {input.ref} -rALL -f {input.fq} -o SAM 2> {log} > {output}"

# | {SAMTOOLS} view -bS - > {output}

rule expressreps:
    input:
        "express/bams/{sample}.sorted.bam"
    output:
        "express/reports/{sample}/results.xprs"
    log:
        "logs/express/{sample}.log"
    shell:
        """
        mkdir -p {output}
        {EXPR} {CDNA}.fa {input} --max-read-len 500 -o {output} 2> {log}
        """

##### Annotation #####
rule htseq:
    input:
        sample = "mapped/{sample}.sorted.bam", gtf = GTFFILE
    output:
        id = "counts/{sample}.tsv"
    threads:
        1
    shell:
        """
        {SAMTOOLS} view -h {input.sample} | htseq-count --mode intersection-strict --stranded no --minaqual 1 --type exon --idattr gene_id - {input.gtf} > {output.id}
        """

##### Report #####
rule report:
    input:
        COUNTS, star = STARLOGS, ercc = "ercc.counts", source = "diffExp.Rmd"
    output:
        state = "diffExp.state.RData", html = "diffExp.html",  cds = "cds.df.RData", mr = "muscleResults.csv", hr = "heartResults.csv", raw = "raw_counts.tab.txt", norm = "normalized_counts.tab.txt"
    run:
        R("""
		library(rmarkdown)
		STARLOGS<-"{input.star}"
		ERCC_COUNTS<-"{input.ercc}"
		RAW_COUNTS<-"{output.raw}"
		NORM_COUNTS<-"{output.norm}"
		CDS_FILE<-"{output.cds}"
		HEART_RES<-"{output.hr}"
		MUSCLE_RES<-"{output.mr}"
				
		MUSCLE_KO<-unlist(strsplit("{MUSCLE_KO}", " "));
		MUSCLE_WT<-unlist(strsplit("{MUSCLE_WT}", " "));
		HEART_KO<-unlist(strsplit("{HEART_KO}", " "));
		HEART_WT<-unlist(strsplit("{HEART_WT}", " "));
		
		samples<-c(MUSCLE_KO,MUSCLE_WT,HEART_KO,HEART_WT)
		save(STARLOGS,ERCC_COUNTS,RAW_COUNTS,NORM_COUNTS,CDS_FILE,HEART_RES,MUSCLE_RES,MUSCLE_KO,MUSCLE_WT,HEART_KO,HEART_WT,samples,file="diffExp.state.RData")
		rmarkdown::render("{input.source}",output_file="{output.html}")
		""")

rule gage:
    input:
        cds = "cds.df.RData", gage = "common/rna-seq/gage.R"
    output:
        GAGE_FILES
    run:
        R("""
		source("{input.gage}")
    
    refMuscleCols<-5:8
    altMuscleCols<-1:4
    refHeartCols<-13:16
    altHeartCols<-9:12
    
    go.mf.muscle<-writeGageTables("muscle","molecular_function","GO",go.mf.mm,refMuscleCols,altMuscleCols,TRUE)
    go.cc.muscle<-writeGageTables("muscle","cellular_component","GO",go.cc.mm,refMuscleCols,altMuscleCols,TRUE)
    go.bp.muscle<-writeGageTables("muscle","biological_process","GO",go.bp.mm,refMuscleCols,altMuscleCols,TRUE)
    
    go.mf.heart<-writeGageTables("heart","molecular_function","GO",go.mf.mm,refHeartCols,altHeartCols,TRUE)
    go.cc.heart<-writeGageTables("heart","cellular_component","GO",go.cc.mm,refHeartCols,altHeartCols,TRUE)
    go.bp.heart<-writeGageTables("heart","biological_process","GO",go.bp.mm,refHeartCols,altHeartCols,TRUE)
    
    kg.mm<-kegg.gsets(species='mouse')
    kegg.sigmet<-kg.mm$kg.sets[kg.mm$sigmet.idx]
    kegg.muscle<-writeGageTables("muscle","signaling_or_metabolism_pathways","KEGG",kegg.sigmet,refMuscleCols,altMuscleCols,FALSE)
    kegg.heart<-writeGageTables("heart","signaling_or_metabolism_pathways","KEGG",kegg.sigmet,refHeartCols,altHeartCols,FALSE)
		""")

rule submodule_update:
    run:
        """git submodule foreach git pull origin master"""

rule topgo_data:
    input:
        results = "{tissue}Results.csv", source = "common/rna-seq/topGO.R"
    output:
        "{tissue}GO.RData"
    run:
        R("""
			source("{input.source}")
			res<-read.csv("{input.results}")
			de<-hot<-cold<-list()
			for(ont in c('BP','CC','MF')){{
			  de[[ont]]<-getGO(res,ontology=ont,desc=paste("{wildcards.tissue}",ont,"most sig de"),q.column="pval",scoreOrder="increasing")
			  hot[[ont]]<-getGO(res,ontology=ont,desc=paste("{wildcards.tissue}",ont,"most upreg in ANT1 wort pval"),q.column="foldChange",scoreOrder="decreasing")
			  cold[[ont]]<-getGO(res,ontology=ont,desc=paste("{wildcards.tissue}",ont,"most downreg in ANT1 wort pval"),q.column="foldChange",scoreOrder="increasing")
			}}
			GOs<-list(de=de,hot=hot,cold=cold)
			save(GOs,file="{output}")
		""")

rule topgo_report:
    input:
        source = "topGO.Rnw", mg = "muscleGO.RData", hg = "heartGO.RData"
    output:
        tex = "topGO.tex"
    run:
        R("""
		Sweave("{input.source}",output="{output.tex}")
		""")

# we do it twice for the TOC
rule pdflatex:
    input:
        "{report}.tex"
    output:
        "{report}.pdf"
    shell:
        "pdflatex {input}; pdflatex {input}"

#### Tracks #####
rule bamtobdg:
    input:
        sample = "mapped/{sample}.sorted.bam", ref = FASTAREF
    output:
        "mapped/{sample}.bdg"
    shell:
        "{BEDTOOLS}/bedtools genomecov -ibam {input.sample} -g {input.ref} -bg > {output}"

rule chrify:
    input:
        "{sample}.bdg"
    output:
        "{sample}.bdg.chr"
    shell:
        """
        cat {input} | sed -e 's/^/chr/'  | sed -e 's/^chrMT/chrM/'> {output}
        """

rule bigwig:
    input:
        "mapped/{sample}.bdg.chr"
    output:
        "tracks/{sample}.bw"
    shell:
        """
        {TOOLDIR}/bedGraphToBigWig {input} mm10.len {output}
        """

#### Site #####
SLINK = "{{SLINK}}"
COLORS = """
141,211,199
255,255,179
190,186,218
251,128,114
128,177,211
253,180,98
179,222,105
252,205,229
217,217,217
188,128,189
204,235,197
255,237,111
190,174,212
253,192,134
56,108,176
191,91,23
""".split()

rule siteindex:
    input:
        "Snakefile"
	#, BIGWIGS, "diffExp.pdf", "topGO.pdf", QCED, RNASEQC_INDEX
    output:
        "site/index.md"
    run:
        with open(output[0], 'w') as outfile:
            outfile.write("""
### Quality Control
#### FastQC Output
[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc) is quality control tool that can point to certain biases that represent contamination. Be aware, the report may reflect inherent biases in the RNA-Seq experiment.
""")
            for s, p in zip(SAMPLES, PRETTY_NAMES):
                outfile.write(
                    "> [`{0}`]({1}/fastqc/{2}.trimmed_fastqc/fastqc_report.html)\n\n".format(p, SLINK, s))
            outfile.write("""
		
#### RNA-SeQC Output
[RNA-SeQC](http://bioinformatics.oxfordjournals.org/content/28/11/1530.long) produces extensive metrics for RNA-Seq runs. Not all of the sections will apply to the Ion Proton protocol.
Most interesting might be the rRNA rate in the multisample [summary document]({0}/{1}/countMetrics.html).
> [RNA-SeQC home]({0}/{2})

> [RNA-SeQC reports]({0}/{1}/countMetrics.html)

> [RNA-SeQC reports]({0}/{1}/report.html)

### HT-Seq Counts
> [Raw HT-Seq Counts]({0}/raw_counts.tab.txt)

> [ERCC Spike-in Normalized Counts]({0}/normalized_counts.tab.txt)

### Gene Reads
For downstream amplification purposes, reads aligning to the following genes were extracted from the alignments

> MT-ND1 ENSMUSG00000064341

> MT-ND3 ENSMUSG00000064360

> MT-ND6 ENSMUSG00000064368

> MT-CYTB ENSMUSG00000064370

Note: Many of these reads are soft-clipped (i.e. a local alignment in which end of the read does not align with reference).
Also the intersection rules employed for differential expression are more strict than those used in the extraction. The [intersection-strict](http://www-huber.embl.de/users/anders/HTSeq/doc/count.html) mode was used for DE.
Counts will be proportional but different than those in [Raw HT-Seq Counts]({0}/raw_counts.tab.txt).

For brevity these output are hidden from this report.
""")
            #outfile.write("> [Gene reads]({0}/gene_reads)".format(SLINK))
            #for s in GENEREADS:
            #    outfile.write("> [`{0}`]({1}/{0})\n\n".format(s, SLINK))
            outfile.write("""
### Differential expression analysis report and significantly DE gene tables
> [diffExp.html](diffExp.html)

> [muscleResults.csv]({0}/muscleResults.csv)

> [heartResults.csv]({0}/heartResults.csv)

### Convenience tables for Metacore aka GeneGo
These are just lists of HUGO identifiers, log2 fold changes, and padj. All genes with at least 100 reads across all lanes and HUGO mappings are included.
> [heart.genego.xls]({0}/heart.genego.xls)

> [muscle.genego.xls]({0}/muscle.genego.xls)    

### GAGE
GAGE was used to generate GO and KEGG pathway analysis using a ranked list analysis (read counts are taken into consideration)

#### Gene Ontology with GAGE
GO is divided into domains of cellular component, molecular function, and biological process.

The "up" and "down" tables test the model that ANT1 is overexpressing/underexpressing all genes in a geneset associated with a GO term relative to B6ME. The same GO terms are in both files.

This describes the tables included in this GAGE output.

Column    | Description
----------|------------
p.geomean | geometric mean of the individual p-values from multiple single array based gene set tests
stat.mean | mean of the individual statistics from multiple single array based gene set tests. Normally, its absoluate value measures the magnitude of gene-set level changes, and its sign indicates direction of the changes.
p.val     | global p-value or summary of the individual p-values from multiple single array based gene set tests. This is the default p-value being used.
q.val     | FDR q-value adjustment of the global p-value using the Benjamini & Hochberg procedure implemented in multtest package. This is the default q-value being used.
set.size  | the effective gene set size, i.e. the number of genes included in the gene set test
""".format(SLINK,RNASEQC_DIR,RNASEQC_INDEX))
            for f in GAGE_GO_FILES:
                outfile.write(">[{0}]({1}/{0})\n\n".format(f,SLINK))
            outfile.write("""
### KEGG Pathway Enrichment with GAGE
The GAGE KEGG analysis does not assume expression is in one direction.
""")
            for f in GAGE_KEGG_FILES:
                outfile.write(">[{0}]({1}/{0})\n\n".format(f,SLINK))
            outfile.write("""
### TopGO Analysis
TopGO provides additional tools for exploring GO enrichment.
> [topGO.pdf]({0}/topGO.pdf)

### Using BigWig Tracks in UCSC Genome Browser
Go to [http://genome.ucsc.edu/cgi-bin/hgCustom](http://genome.ucsc.edu/cgi-bin/hgCustom), make sure mm10 is selected, and copy-paste one or more of these into the URL field.
""".format(SLINK))
            for c, b, p in zip(COLORS, BIGWIG_NAMES, PRETTY_NAMES):
                outfile.write(
                    "> ```track type=bigWig name={0} db=mm10 smoothingWindow=4 color={1} autoScale=on viewLimits=1:200 visibility=full windowingFunction=maximum bigDataUrl={3}/{2}```\n\n".format(p, c, b, S3_LINK))
            outfile.write("""
### Code repository
Code used to generate this analysis is located here [http://github.research.chop.edu/BiG/martin-ant1-rnaseq](http://github.research.chop.edu/BiG/martin-ant1-rnaseq). Feel free to reuse.

### Git hash
This should match the hash index on the last page of your report.
""")
            outfile.write('```{0}```\n\n'.format(get_head_hash()))
            outfile.write(
                'Last modified ```{0}```'.format(strftime("%Y-%m-%d %H:%M:%S")))


rule publishsite:
    input:
        "site/index.md"
    shell:
        """
        jekyll build --config site/_config.yml --source site --destination site/_site
        rsync -v --update --rsh=ssh -r site/_site/* {WEBSITE}
        """

rule publishdata:
    input:
        QCED, GAGE_GO_FILES, GAGE_KEGG_FILES, "diffExp.pdf", "topGO.pdf"
    shell:
        """
        rsync -v --update --rsh=ssh -r diffExp.pdf topGO.pdf muscleResults.csv heartResults.csv fastqc raw_counts.tab.txt normalized_counts.tab.txt RNASEQC_DIR GAGE {WEBSITE}
        """

rule publishtracks:
    input:
        BIGWIGS
    shell:
        """
        aws s3 --profile leipzig cp tracks/ {S3_BUCKET} --recursive --exclude "*" --include "*.bw" --acl public-read
        """


def get_head_hash():
    return os.popen('git rev-parse --verify HEAD 2>&1').read().strip()


##########################
#--outFilterIntronMotifs RemoveNoncanonical
#-library-type=fr-secondstrand unclear if this is appropriate
# http://seqanswers.com/forums/showthread.php?t=9418
# http://ioncommunity.lifetechnologies.com/docs/DOC-7062

# java -jar picard-tools-1.106/CreateSequenceDictionary.jar REFERENCE= ../refs/Mus_musculus/Ensembl/GRCm38/Sequence/WholeGenomeFasta/genome.fa OUTPUT= ../refs/Mus_musculus/Ensembl/GRCm38/Sequence/WholeGenomeFasta/genome.dict
# perl -ne 'm/^([0-9]+|MT|X|Y)/ && print'
# /nas/is1/leipzig/martin/snake-env/refs/Mus_musculus/Ensembl/GRCm38/Annotation/Genes/genes.gtf
# >
# /nas/is1/leipzig/martin/snake-env/refs/Mus_musculus/Ensembl/GRCm38/Annotation/Genes/primary_genes.gtf

##### ROOT (not used) ####
def get_isilon_mount_path():
    if socket.gethostname() == 'respublica':
        return '/mnt/isilon/cbmi/variome/'
    else:
        return '/nas/is1/'

ROOT = get_isilon_mount_path() + "leipzig/martin/snake-env/"
