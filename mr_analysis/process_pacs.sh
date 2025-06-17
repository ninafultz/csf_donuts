#!/bin/bash

# Define the base project path
BASE_DIR="/exports/gorter-hpc/users/ninafultz/csfdonuts_lydiane"

# List of special cases where the T1 filename is different
SPECIAL_CASES=("20201014_Reconstruction" "20201016_Reconstruction" "20201008_Reconstruction")

# Loop through all subject folders in the base directory
for SUBJECT_DIR in "$BASE_DIR"/*/; do
    # Extract the subject folder name
    SUBJECT_NAME=$(basename "$SUBJECT_DIR")

    # Define paths
    REORIENTED_DIR="${SUBJECT_DIR}reoriented"
    PACS_DIR="${SUBJECT_DIR}pacs_dicoms"

    # Create pacs_dicoms folder if it doesn't exist
    mkdir -p "$PACS_DIR"

    # Determine which T1 file to use
    if [[ " ${SPECIAL_CASES[@]} " =~ " ${SUBJECT_NAME} " ]]; then
        T1_FILE="r3dT1_0.9mm_to_B0_properOrientation.nii"
    else
        T1_FILE="3dT1_0.9mm_to_B0_properOrientation.nii"
    fi

    # List of files to copy
    FILES_TO_COPY=(
        "B0_from_mhd.nii"
        "masked_b0_ADC_mhd_thr150.0000.nii"
        "$T1_FILE"
    )

    # Copy each file if it exists
    for FILE in "${FILES_TO_COPY[@]}"; do
        if [[ -f "$REORIENTED_DIR/$FILE" ]]; then
            cp "$REORIENTED_DIR/$FILE" "$PACS_DIR/"
        else
            echo "Warning: $FILE not found in $REORIENTED_DIR"
        fi
    done

    # Apply the FSL command on masked_b0_ADC_mhd_thr150.0000.nii
    if [[ -f "$PACS_DIR/masked_b0_ADC_mhd_thr150.0000.nii" ]]; then
        fslmaths "$PACS_DIR/masked_b0_ADC_mhd_thr150.0000.nii" -mul 10000 "$PACS_DIR/masked_b0_ADC_mhd_thr150.0000_multi10000.nii.gz"

        # Convert the compressed .nii.gz to uncompressed .nii using mri_convert
        mri_convert "$PACS_DIR/masked_b0_ADC_mhd_thr150.0000_multi10000.nii.gz" "$PACS_DIR/masked_b0_ADC_mhd_thr150.0000_multi10000.nii"

        # Optionally, remove the .nii.gz version after conversion
        rm "$PACS_DIR/masked_b0_ADC_mhd_thr150.0000_thr2_multi2.nii.gz"
    else
        echo "Warning: masked_b0_ADC_mhd_thr150.0000.nii not found in $PACS_DIR"
    fi

done
