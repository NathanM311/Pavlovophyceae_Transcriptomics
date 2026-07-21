#!/bin/bash
set -e
# ------------------------------------------------------------------
# SCRIPT 03: rRNA DEPLETION USING SORTMERNA (FAST & SECURE VERSION)
# ------------------------------------------------------------------

# 1. STRICT MODE: Script stops immediately if a command fails
set -e

# 2. READ SAMPLE ID
SAMPLE=${1:-"Sample_ID"}

BASE_DIR="/path/to/your/project"

source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate rnaseq

# 3. DIRECTORIES (Must match the output from Script 02)
INPUT_DIR="$BASE_DIR/02_results/02_phix_removed/${SAMPLE}"
OUTPUT_DIR="$BASE_DIR/02_results/03_sortmerna"
DB_DIR="$BASE_DIR/01_data/sortmerna"

SAMPLE_OUT_DIR="$OUTPUT_DIR/$SAMPLE"
mkdir -p $SAMPLE_OUT_DIR

# 4. FILE PATHS & EXTENSIONS (.fq.gz)
R1="${INPUT_DIR}/${SAMPLE}_no_phix_R1.fq.gz"
R2="${INPUT_DIR}/${SAMPLE}_no_phix_R2.fq.gz"
REF_DB="${DB_DIR}/smr_v4.3_default_db.fasta"

# ==================================================================
# 5. LOCAL DISK OPTIMIZATION (To prevent slow network I/O bottlenecks)
LOCAL_WORKDIR="/tmp/sortmerna_${SAMPLE}"
mkdir -p $LOCAL_WORKDIR
# ==================================================================

echo "==================================================="
echo "🧬 Running SortMeRNA rRNA depletion for: $SAMPLE"
echo "==================================================="

# Running the tool on the local SSD workspace
sortmerna \
    --ref $REF_DB \
    --reads $R1 \
    --reads $R2 \
    --workdir $LOCAL_WORKDIR \
    --aligned $SAMPLE_OUT_DIR/${SAMPLE}_ribosome \
    --other $SAMPLE_OUT_DIR/${SAMPLE}_noribosome \
    --paired_in \
    --out2 \
    --fastx \
    --threads 14

echo "🗜️ Checking and compressing results..."
gzip -f $SAMPLE_OUT_DIR/${SAMPLE}_ribosome_fwd.fq 2>/dev/null || true
gzip -f $SAMPLE_OUT_DIR/${SAMPLE}_ribosome_rev.fq 2>/dev/null || true
gzip -f $SAMPLE_OUT_DIR/${SAMPLE}_noribosome_fwd.fq 2>/dev/null || true
gzip -f $SAMPLE_OUT_DIR/${SAMPLE}_noribosome_rev.fq 2>/dev/null || true

# Local workspace cleanup
rm -rf $LOCAL_WORKDIR

echo "✅ rRNA DEPLETION COMPLETED SUCCESSFULLY. FILES SAVED IN: $SAMPLE_OUT_DIR"