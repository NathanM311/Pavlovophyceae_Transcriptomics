# Pavlovophyceae Transcriptomics and Microbiome Profiling Pipeline

This repository contains the complete bioinformatics pipeline used for the RNA-sequencing data processing, *de novo* transcriptome assembly, and taxonomic profiling of non-axenic microalgae cultures, as described in the manuscript.

##  Overview

The pipeline is designed to process paired-end (150-bp) Illumina NovaSeq X reads. It performs stringent quality control, *in silico* ribosomal RNA (rRNA) depletion, multi-assembler transcript reconstruction, and dual quantification of both the microalgal host (mRNA) and its associated microbiome (rRNA). 

To ensure full transparency and reproducibility, the data processing is broken down into 8 sequential Bash scripts.

##  Software Dependencies

The scripts rely on Conda environments. Ensure the following tools and exact versions are installed to replicate the study's environment:

| Step | Tool | Version | Purpose |
|------|------|---------|---------|
| **QC & Trimming** | Trim Galore (Cutadapt) | v0.6.10 | Adapter removal & quality trimming |
| **QC & Trimming** | Bowtie 2 | v2.5.4 | Illumina phiX control removal |
| **rRNA Depletion** | SortMeRNA | v4.3.6 | *In silico* separation of mRNA and rRNA |
| **Assembly** | Trinity | v2.1.1 | *De novo* assembly (mRNA & rRNA) |
| **Assembly** | rnaSPAdes | v4.2.0 | *De novo* assembly (mRNA) |
| **Assembly** | RNA-Bloom | v2.0.1 | *De novo* assembly (mRNA) |
| **Dereplication**| MMseqs2 | v18.8cc5c | 99% sequence identity clustering |
| **Taxonomy** | BLASTn | v2.16.0 | Alignment against PR2 and SILVA |
| **Quantification**| Kallisto | v0.51.1 | Transcript abundance estimation (TPM) |
| **Visualization**| KronaTools | v2.8.1 | Interactive taxonomic profiling |

*Databases used:* **PR2** (v5.1.1) and **SILVA SSU/LSU** (release 138.1).

---

##  Pipeline Execution (Step-by-Step)

Before running the scripts, users must update the `BASE_DIR` and `SAMPLE_MAP` variables inside the scripts to match their local cluster paths and sample names.

### Phase 1: Data Pre-processing
* **`01_qc_and_trimming.sh`**: Raw reads are subjected to quality control and trimming to remove adapter sequences and low-quality bases.
* **`02_remove_phix.sh`**: Filtering out of Illumina phiX control reads using Bowtie 2.
* **`03_rrna_depletion_sortmerna.sh`**: Reads undergo an *in silico* rRNA depletion step. mRNA and rRNA reads are segregated into distinct sets for downstream assembly.

### Phase 2: *De novo* Assembly & Clustering
* **`04_multi_assembly.sh`**: To maximize completeness, a multi-assembler strategy (Trinity, rnaSPAdes, RNA-Bloom) is applied to the mRNA-enriched reads. Ribosomal reads are assembled separately using Trinity.
* **`05_clustering_mmseqs.sh`**: Resulting multi-assemblies are dereplicated at a strict 99% sequence identity threshold to generate a unique, non-redundant transcript catalog.

### Phase 3: Quantification
* **`06_quantification_kallisto.sh`**: Transcript abundance is quantified in Transcripts Per Million (TPM) for both the clustered mRNA catalog (for differential expression) and the ribosomal assemblies (for microbiome profiling).

### Phase 4: Taxonomic Annotation & Decontamination
* **`07a_taxonomic_assignment_blast.sh`**: Ribosomal contigs are taxonomically assigned against PR2 and SILVA databases, retaining only top hits with $\ge$ 90% identity and an alignment length of $\ge$ 200 bp.
* **`07b_taxonomic_decontamination.sh`**: A custom filter systematically identifies and excludes sequences mapping to known laboratory contaminants (e.g., *Staphylococcus*, *Cutibacterium*, *Betula*, *Aspergillus*, and non-target metazoans).

### Phase 5: Visualization
* **`08_taxonomic_profiling_krona.sh`**: Generates interactive HTML taxonomic profiles. To provide full transparency, the dashboard visualizes both the pre-filtering (raw) and post-decontamination (clean) datasets.

---

##  Data Availability
Raw RNA-seq datasets generated in this study are available in the NCBI Sequence Read Archive (SRA) under BioProject **PRJNA1453970**.
