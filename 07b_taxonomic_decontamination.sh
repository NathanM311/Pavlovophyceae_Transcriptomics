#!/bin/bash
set -e
# ------------------------------------------------------------------
# SCRIPT 07b: TAXONOMIC DECONTAMINATION (CUSTOM FILTERING)
# PURPOSE: Remove sequences mapping to known laboratory contaminants
# ------------------------------------------------------------------

SAMPLE=${1:-"Sample_ID"}
BASE_DIR="/path/to/your/project"
TAX_DIR="${BASE_DIR}/02_results/05_taxonomy/${SAMPLE}"

# 🛑 Comprehensive Blacklist (Based on visual audit & manuscript definition)
# Includes: Human-associated microbes, Kitome, Terrestrial plants (Betula), Insects, and Terrestrial fungi
CONTAMINANTS="Homo sapiens|Homo|Escherichia|Staphylococcus|Streptococcus|Cutibacterium|Propionibacterium|Mycoplasma|Ralstonia|Bradyrhizobium|Acinetobacter|Malassezia|Enterobacter|Salmonella|Shigella|Brevundimonas|Sphingomonas|Betula|Insecta|Psychoda|Aspergillus|Fungi|Dikarya|Metazoa|Choanozoa"

echo "===================================================================="
echo "🧽 DATA DECONTAMINATION FOR SAMPLE: $SAMPLE"
echo "===================================================================="

if [ ! -d "$TAX_DIR" ]; then
    echo "❌ ERROR: Taxonomy directory not found ($TAX_DIR)."
    exit 1
fi

# Loop through each _CLEAN.tsv file (output from the BLAST step)
for FILE in "${TAX_DIR}"/*_CLEAN.tsv; do
    # Skip files that have already been decontaminated
    if [[ "$FILE" == *"no_contaminants"* ]]; then continue; fi
    
    if [ -f "$FILE" ]; then
        BASENAME=$(basename "$FILE")
        OUT_FILE="${FILE/.tsv/_no_contaminants.tsv}"
        
        echo "🔍 Processing: $BASENAME"
        
        # 1. Keep the header
        head -n 1 "$FILE" > "$OUT_FILE"
        
        # 2. Filter out contaminants (case-insensitive, extended regex)
        tail -n +2 "$FILE" | grep -v -i -E "$CONTAMINANTS" >> "$OUT_FILE"
        
        # --- Statistics ---
        TOTAL=$(tail -n +2 "$FILE" | wc -l)
        KEPT=$(tail -n +2 "$OUT_FILE" | wc -l)
        REMOVED=$((TOTAL - KEPT))
        
        echo "   -> Total transcripts : $TOTAL"
        echo "   -> Retained marine signal : 🌊 $KEPT"
        echo "   -> Removed noise/contaminants : 💥 $REMOVED"
        echo "   -> Output file : $(basename "$OUT_FILE")"
        echo "------------------------------------------------"
    fi
done

echo "✅ Decontamination completed successfully!"
echo "===================================================================="