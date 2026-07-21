#!/bin/bash
# ------------------------------------------------------------------
# SCRIPT 01 : QUALITY CLEANING AND ADAPTERS (TRIMGALORE)
# ------------------------------------------------------------------

SAMPLE=${1:-"Sample_ID"}
BASE_DIR="/path/to/your/project"

# Directories
INPUT_DIR="${BASE_DIR}/01_data/raw_data/${SAMPLE}"
OUT_DIR="${BASE_DIR}/02_results/01_trimmed"
mkdir -p $OUT_DIR

# File identification (based on Illumina file names)
R1="${INPUT_DIR}/${SAMPLE}_S10_L001_R1_001.fastq.gz"
R2="${INPUT_DIR}/${SAMPLE}_S10_L001_R2_001.fastq.gz"

echo "✂️ Trimming in progress for: $SAMPLE"

# Using TrimGalore (often in the 'rnaseq' env)
trim_galore --paired \
            --quality 20 \
            --fastqc \
            --illumina \
            --gzip \
            --cores 14 \
            -o $OUT_DIR \
            $R1 $R2

echo "✅ Trimming completed. Files in: $OUT_DIR"