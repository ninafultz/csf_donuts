#!/bin/bash

# Script to merge echoes based on common prefix
# Usage: ./merge_echoes.sh -n <subject_name> -d <directory_path>

display_usage(){
    echo "***************************************************************************************"
    echo "Script to merge multi-echo MRI files based on common prefix using AFNI's 3dTcat"
    echo "***************************************************************************************"
    echo "Usage: ./merge_echoes.sh -n <subject_name> -d <directory_path>"
    echo "   -n: Name of subject"
    echo "   -d: Directory path"
}

if [ $# -le 1 ]; then
    display_usage
    exit 1
fi

while getopts "n:d:" opts; do
    case $opts in
        n) SUBJECT=${OPTARG} ;;
        d) DIR=${OPTARG} ;;
        *) display_usage
           exit 1 ;;
    esac
done

# Check if directory exists
if [ ! -d "$DIR/$SUBJECT/func" ]; then
    echo "Error: Directory '$DIR/$SUBJECT/func' not found!"
    exit 1
fi

# Navigate to the functional directory
cd "$DIR/$SUBJECT/func" || exit 1

# Find all echo files
echo_files=$(find . -maxdepth 1 -type f -name '*_e*.nii.gz')
num_echoes=$(echo "$echo_files" | wc -l)

# Check number of echo files
if [ $num_echoes -eq 0 ]; then
    echo "Error: No echo files found in '$DIR/$SUBJECT/func'"
    exit 1
fi

# Extract unique prefixes based on the common part before _e<number>.nii.gz
prefixes=($(echo "$echo_files" | sed 's/_[^_]*\.nii\.gz$//' | sort -u))

# Check if exactly 4 echoes are found for each prefix
for prefix in "${prefixes[@]}"; do
    prefix_files=($(echo "$echo_files" | grep "$prefix"))
    if [ ${#prefix_files[@]} -ne 4 ]; then
        echo "Error: Found ${#prefix_files[@]} echo files for prefix '$prefix'. Exactly 4 echoes are required for each prefix."
        exit 1
    fi
done

# Merge echoes for each unique prefix
for prefix in "${prefixes[@]}"; do
    echo_files_to_merge=($(echo "$echo_files" | grep "$prefix"))
    sorted_echo_files=($(echo "${echo_files_to_merge[@]}" | sort))

    # Remove leading "./" from prefix if it exists
    prefix=$(echo "$prefix" | sed 's|^./||')

    # Construct the merged output name
    merged_name="merged_${prefix}.nii.gz"

    # Construct the 3dTcat command
    cmd="3dTcat -prefix $merged_name ${sorted_echo_files[@]}"
    echo "Executing command: $cmd"

    # Execute the 3dTcat command
    $cmd

    echo "Echoes merged successfully for prefix '$prefix' to '$merged_name'"
done
