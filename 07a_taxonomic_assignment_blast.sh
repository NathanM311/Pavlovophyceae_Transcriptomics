#!/bin/bash
set -e
# ------------------------------------------------------------------
# SCRIPT 07a: TAXONOMIC ASSIGNMENT (BLASTn - PR2 + SILVA SSU/LSU)
# PURPOSE: Assign taxonomy to ribosomal contigs and apply structural filters
# ------------------------------------------------------------------

START_TIME=$(date +%s)
BASE_DIR="/path/to/your/project"
SAMPLE=${1:-"Sample_ID"}

# Paths
QUERY_FASTA="${BASE_DIR}/02_results/04_assembly/${SAMPLE}/ribosome_trinity.Trinity.fasta"
OUT_DIR="${BASE_DIR}/02_results/05_taxonomy/${SAMPLE}"

# Database directories
DB_DIR_PR2="${BASE_DIR}/01_data/ribosomes/PR2"
DB_DIR_SILVA="${BASE_DIR}/01_data/ribosomes/Silva"

mkdir -p "$OUT_DIR"

echo "===================================================================="
echo "🚀 STARTING MULTI-DATABASE TAXONOMIC ANNOTATION"
echo "🧬 Sample: $SAMPLE"
echo "===================================================================="

echo "🔄 Loading env_blast..."
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate env_blast

# ------------------------------------------------------------------
# 1. BLAST against PR2 (Eukaryotes / Chloroplasts Reference)
# ------------------------------------------------------------------
echo "🔬 [1/4] Running BLASTn against PR2 v5.1.1..."
blastn -query "$QUERY_FASTA" \
       -db "$DB_DIR_PR2/PR2_v5.1.1_db" \
       -out "$OUT_DIR/${SAMPLE}_vs_PR2.tsv" \
       -evalue 1e-5 \
       -num_threads 14 \
       -max_target_seqs 5 \
       -outfmt "6 qseqid sseqid pident length evalue bitscore stitle"

# ------------------------------------------------------------------
# 2. BLAST against SILVA SSU (16S/18S)
# ------------------------------------------------------------------
echo "🔬 [2/4] Running BLASTn against SILVA SSU..."
blastn -query "$QUERY_FASTA" \
       -db "$DB_DIR_SILVA/SILVA_SSU_db" \
       -out "$OUT_DIR/${SAMPLE}_vs_SILVA_SSU.tsv" \
       -evalue 1e-5 \
       -num_threads 14 \
       -max_target_seqs 5 \
       -outfmt "6 qseqid sseqid pident length evalue bitscore stitle"

# ------------------------------------------------------------------
# 3. BLAST against SILVA LSU (23S/28S)
# ------------------------------------------------------------------
echo "🔬 [3/4] Running BLASTn against SILVA LSU..."
blastn -query "$QUERY_FASTA" \
       -db "$DB_DIR_SILVA/SILVA_LSU_db" \
       -out "$OUT_DIR/${SAMPLE}_vs_SILVA_LSU.tsv" \
       -evalue 1e-5 \
       -num_threads 14 \
       -max_target_seqs 5 \
       -outfmt "6 qseqid sseqid pident length evalue bitscore stitle"

# ------------------------------------------------------------------
# 4. DATA CLEANING (Top Hit, Threshold Filters, Header Formatting)
# ------------------------------------------------------------------
echo "🧹 [4/4] Filtering and formatting results..."

# Filtering parameters (As defined in the manuscript)
MIN_ID=90
MIN_LEN=200

# Files to process
FILES=(
    "${SAMPLE}_vs_PR2.tsv"
    "${SAMPLE}_vs_SILVA_SSU.tsv"
    "${SAMPLE}_vs_SILVA_LSU.tsv"
)

for FILE in "${FILES[@]}"; do
    INPUT="$OUT_DIR/$FILE"
    OUTPUT="$OUT_DIR/${FILE/.tsv/_CLEAN.tsv}" # Outputs _CLEAN.tsv for script 07b
    
    if [ -s "$INPUT" ]; then 
        if [[ "$FILE" == *"PR2"* ]]; then
            # Specific parsing for PR2 (Splitting the | delimiters)
            echo "  -> Formatting PR2 results for $FILE..."
            awk -F'\t' -v OFS='\t' -v id="$MIN_ID" -v len="$MIN_LEN" '
            BEGIN {print "Contig_ID\tRef_ID\tGene\tOrganelle\tStrain\tDomain\tSupergroup\tDivision\tSubdivision\tClass\tOrder\tFamily\tGenus\tSpecies\tIdentity_pct\tAlign_Length\tE-value\tBitscore"}
            !vus[$1]++ && $3 >= id && $4 >= len {
                split($2, tax, "|")
                print $1, tax[1], tax[2], tax[3], tax[4], tax[5], tax[6], tax[7], tax[8], tax[9], tax[10], tax[11], tax[12], tax[13], $3, $4, $5, $6
            }
            ' "$INPUT" > "$OUTPUT"
            
        else
            # Standard parsing for SILVA (Taxonomy in column 7)
            echo "  -> Formatting SILVA results for $FILE..."
            awk -F'\t' -v OFS='\t' -v id="$MIN_ID" -v len="$MIN_LEN" '
            BEGIN {print "Contig_ID\tRef_ID\tIdentity_pct\tAlign_Length\tE-value\tBitscore\tTaxonomy"}
            !vus[$1]++ && $3 >= id && $4 >= len {
                gsub(/\|/, ";", $7)
                print $1, $2, $3, $4, $5, $6, $7
            }
            ' "$INPUT" > "$OUTPUT"
        fi
        
    else
        echo "  ⚠️ File $FILE is empty or missing, skipping."
    fi
done

# ------------------------------------------------------------------
# END OF SCRIPT
# ------------------------------------------------------------------
conda deactivate

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
H=$((ELAPSED / 3600))
M=$(((ELAPSED % 3600) / 60))

echo "===================================================================="
echo "✅ BLAST ALIGNMENTS AND FILTERING COMPLETED IN ${H}h ${M}m !"
echo "📊 Clean results available in: $OUT_DIR/"
echo "===================================================================="