#!/bin/bash
set -e

# ------------------------------------------------------------------
# SCRIPT 08: GLOBAL KRONA HTML REPORT (MULTI-SAMPLE)
# PURPOSE: Merge, filter, and rename samples to generate an interactive 
# Krona HTML report for data exploration.
# ------------------------------------------------------------------

BASE_DIR="/path/to/your/project"
ANALYSE_DIR="${BASE_DIR}/02_results/Analyse"
MASTER_HTML="${ANALYSE_DIR}/Master_Krona_Report.html"

# ==================================================================
# 📚 SAMPLE DICTIONARY (FILTERING & RENAMING)
# INSTRUCTIONS FOR GITHUB USERS:
# Use the SAMPLE_MAP array to select which samples to include in the 
# final HTML report and how they should be named in the Krona menu.
# Syntax: SAMPLE_MAP["Your_Actual_Folder_Name"]="Display_Name"
# Only the directories listed here will be processed.
# ==================================================================
declare -A SAMPLE_MAP

# --- ADD YOUR OWN SAMPLES BELOW ---
# Example:
# SAMPLE_MAP["sample_01"]="Condition_A_Day_0"
# SAMPLE_MAP["sample_02"]="Condition_B_Day_7"

# <INSERT_YOUR_SAMPLES_HERE>
# -----------------------------------------------

echo "===================================================================="
echo "🌐 GENERATING GLOBAL KRONA HTML REPORT"
echo "===================================================================="

# --- CONDA ENVIRONMENT ---
echo "🔄 Activating Krona environment..."
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate env_krona

KRONA_ARGS=()

# Loop through all sample directories in the Analysis folder
for SAMPLE_DIR in "${ANALYSE_DIR}"/*; do
    if [ -d "$SAMPLE_DIR" ]; then
        SAMPLE=$(basename "$SAMPLE_DIR")
        
        # 🛑 FILTER: Is the sample in our defined map?
        if [[ -z "${SAMPLE_MAP[$SAMPLE]}" ]]; then
            echo "⏭️  Skipping: $SAMPLE (Not required for this report)"
            continue
        fi
        
        # Retrieve the formatted name for the Krona menu
        PRETTY_NAME="${SAMPLE_MAP[$SAMPLE]}"
        
        # Source files (Assumes prior taxonomic unification)
        NUC_NC="${SAMPLE_DIR}/${SAMPLE}_unified_microbiome_nuclear_no_contaminants.tsv"
        ORG_NC="${SAMPLE_DIR}/${SAMPLE}_unified_microbiome_organelles_no_contaminants.tsv"
        TPM_FILE="${BASE_DIR}/02_results/16_quantification_kallisto_all/${SAMPLE}/${SAMPLE}_abundance_ribo_TPM.tsv"
        
        if [ -f "$NUC_NC" ] && [ -f "$TPM_FILE" ]; then
            echo "⏳ Preparing data for: $PRETTY_NAME (Source folder: $SAMPLE)"
            
            TMP_NUC="${SAMPLE_DIR}/tmp_${SAMPLE}_nuc.txt"
            TMP_ORG="${SAMPLE_DIR}/tmp_${SAMPLE}_org.txt"
            
            # Extract TPM values for the NUCLEUS compartment
            awk -F'\t' -v tpm_f="$TPM_FILE" '
                NR==FNR { tpm[$1]=$2; next }
                NR>1 { 
                    val = (tpm[$1] ? tpm[$1] : 0);
                    if (val > 0) print val"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10 
                }
            ' "$TPM_FILE" "$NUC_NC" > "$TMP_NUC"
            
            # Extract TPM values for the ORGANELLES compartment
            awk -F'\t' -v tpm_f="$TPM_FILE" '
                NR==FNR { tpm[$1]=$2; next }
                NR>1 { 
                    val = (tpm[$1] ? tpm[$1] : 0);
                    if (val > 0) print val"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10 
                }
            ' "$TPM_FILE" "$ORG_NC" > "$TMP_ORG"
            
            # Add to Krona arguments array with formatted English labels
            KRONA_ARGS+=("$TMP_NUC,${PRETTY_NAME} - Nucleus")
            KRONA_ARGS+=("$TMP_ORG,${PRETTY_NAME} - Organelles")
        else
            echo "❌ Missing taxonomic or TPM data for $SAMPLE. Please check previous steps."
        fi
    fi
done

# ==========================================
# CREATE FINAL HTML
# ==========================================
echo "📊 Merging selected datasets into the final HTML report..."

ktImportText "${KRONA_ARGS[@]}" -o "$MASTER_HTML"

# --- CLEANUP ---
echo "🧹 Cleaning temporary text files..."
for SAMPLE_DIR in "${ANALYSE_DIR}"/*; do
    if [ -d "$SAMPLE_DIR" ]; then
        rm -f "${SAMPLE_DIR}"/tmp_*.txt
    fi
done

conda deactivate

echo "✅ HTML REPORT GENERATION COMPLETED!"
echo "📂 Final HTML file: $MASTER_HTML"
echo "===================================================================="