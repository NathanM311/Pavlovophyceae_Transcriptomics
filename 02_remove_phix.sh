#!/bin/bash
set -e

# ------------------------------------------------------------------
# SCRIPT 02: PhiX174 CONTAMINANT REMOVAL USING BOWTIE2 (SSD OPTIMIZED)
# ------------------------------------------------------------------

SAMPLE=${1:-"Sample_ID"}
BASE_DIR="/path/to/your/project"

# Network storage paths
INPUT_DIR="${BASE_DIR}/02_results/01_trimmed"
OUTPUT_DIR="${BASE_DIR}/02_results/02_phix_removed/${SAMPLE}"
DB_DIR="${BASE_DIR}/01_data/databases/phix"

mkdir -p $OUTPUT_DIR
mkdir -p $DB_DIR

# ==================================================================
# LOCAL WORKSPACE (High-speed VM SSD to optimize I/O)
LOCAL_TMP="/tmp/phix_${SAMPLE}"
mkdir -p $LOCAL_TMP
# ==================================================================

# 1. Database Indexing
if [ ! -f "${DB_DIR}/phix.1.bt2" ]; then
    echo "📥 Downloading and indexing PhiX genome..."
    wget -q -O ${DB_DIR}/phix.fasta "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_001422.1&rettype=fasta&retmode=text"
    bowtie2-build ${DB_DIR}/phix.fasta ${DB_DIR}/phix > /dev/null
fi

# 2. Locate input files (automatically detects .fq.gz or .fastq.gz)
R1=$(ls ${INPUT_DIR}/*R1*.f*q.gz)
R2=$(ls ${INPUT_DIR}/*R2*.f*q.gz)

echo "==================================================="
echo "🔍 INPUT VERIFICATION:"
ls -lh $R1
ls -lh $R2
echo "==================================================="
echo "🦠 PhiX Removal for sample: $SAMPLE"

# 3. Run Bowtie2
# Note: SAM output is redirected to /dev/null to save disk space.
# Unaligned reads (clean) are written to the local SSD.
bowtie2 -x ${DB_DIR}/phix \
        -1 $R1 -2 $R2 \
        --threads 14 \
        --un-conc-gz ${LOCAL_TMP}/${SAMPLE}_no_phix_R%.fq.gz \
        -S /dev/null 2> ${OUTPUT_DIR}/${SAMPLE}_phix_stats.txt

# 4. Transfer clean files back to network storage
echo "🚚 Transferring clean reads to network drive..."
cp ${LOCAL_TMP}/${SAMPLE}_no_phix_R1.fq.gz ${OUTPUT_DIR}/
cp ${LOCAL_TMP}/${SAMPLE}_no_phix_R2.fq.gz ${OUTPUT_DIR}/

# 5. Local workspace cleanup
rm -rf $LOCAL_TMP

echo "==================================================="
echo "📊 PHIX CLEANUP STATISTICS:"
cat ${OUTPUT_DIR}/${SAMPLE}_phix_stats.txt
echo "==================================================="
echo "✅ Successfully completed! Clean reads located at:"
echo "   ${OUTPUT_DIR}"
echo "==================================================="