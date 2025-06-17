#!/bin/bash

# Usage: ./anats2niftis.sh -s subjDir 

# Display help/usage when -h or --help is specified
display_usage(){
    echo "***************************************************************************************
Script for processing anatomical NIfTI files in bash
***************************************************************************************"
    echo "Usage: ./anats2niftis.sh -s subjDir"
    echo "   -s subjDir    Specify the subject directory"
}

# Check if the script is invoked with at least one argument
if [ $# -le 1 ]; then
    display_usage
    exit 1
fi

# Parse input arguments
while getopts "s:" opts; do
    case $opts in
        s) export SUBJECTS_DIR=$OPTARG ;;
        *) display_usage
           exit 1 ;;
    esac
done

# Define the directory and file patterns
anat_dir="${SUBJECTS_DIR}/anat"
file_pattern_nifti_gz="${anat_dir}/*3dT1_0.9mm*.nii.gz"
file_pattern_nifti="${anat_dir}/*3dT1_0.9mm*.nii"

# Find matching files for both patterns
matching_files=( $(ls $file_pattern_nifti_gz 2>/dev/null) $(ls $file_pattern_nifti 2>/dev/null) )

# Check the number of matching files
if [[ ${#matching_files[@]} -eq 0 ]]; then
    echo "Error: No files found matching the patterns: $file_pattern_nifti_gz or $file_pattern_nifti"
    exit 1
elif [[ ${#matching_files[@]} -gt 1 ]]; then
    echo "Warning: Multiple files found. Using the first one."
fi

# Use the first matching file
first_file="${matching_files[0]}"
echo "Using file: $first_file"

# Ensure the output directory exists
output_dir="${SUBJECTS_DIR}/reg"
mkdir -p "$output_dir"

# Convert the file to the desired location
output_file="${output_dir}/3dT1_0.9mm.nii"
echo "Converting $first_file to $output_file..."
mri_convert "$first_file" "$output_file"

# Verify conversion and copy back to anat directory if needed
if [[ -f $output_file ]]; then
    echo "Conversion successful"
else
    echo "Error: Conversion failed!"
    exit 1
fi

echo "Process completed successfully."

