#!/bin/bash

# Usage information
display_usage() {
    echo "***************************************************************************************"
    echo "Script to take bias corrected, eroded, skull mask and apply it to MEMPRAGE to remove EEG artifact."
    echo "***************************************************************************************"
    echo "Usage: ./masking_out_eeg.sh -n SUBJECT_NAME -d DIRECTORY"
    echo "   -n: Name of subject"
    echo "   -d: Directory containing the subject's data"
    echo "Example: ./masking_out_eeg.sh -n racsleep08 -d /path/to/data"
}

# Check if the correct number of arguments is provided
if [ $# -le 3 ]; then
    display_usage
    exit 1
fi

# Parse command line arguments
while getopts "n:d:" opts; do
    case $opts in
        n) SUBJECT=$OPTARG ;;
        d) DIR=$OPTARG ;;
        *) display_usage
           exit 1 ;;
    esac
done

# Set environment variables
export BC="$DIR/$SUBJECT/biasfield"
export FUNC="$DIR/$SUBJECT/func"
export REG="$DIR/$SUBJECT/reg"

# Find the relevant files
mergedecho_file=$(find $BC -name 'combinedEchoes_all.nii' -print -quit)
csf_file=$(find $REG -name 'r*_CSF.nii' -print -quit)
gm_file=$(find $REG -name 'r*_GM.nii' -print -quit)
wm_file=$(find $REG -name 'r*_WM.nii' -print -quit)
bone_file=$(find $REG -name 'r*_bone.nii' -print -quit)
other_file=$(find $REG -name 'r*_other.nii' -print -quit)

# Ensure all necessary files are found
if [ -z "$mergedecho_file" ] || [ -z "$csf_file" ] || [ -z "$gm_file" ] || [ -z "$wm_file" ] || [ -z "$bone_file" ] || [ -z "$other_file" ]; then
    echo "One or more necessary files could not be found. Please check the biasfield directory."
    echo "$mergedecho_file"
    echo "$csf_file"
    echo "$gm_file"
    echo "$wm_file"
    echo "$bone_file"
    echo "$other_file"
    exit 1
fi

# Combine various masks into one
combined_mask="$BC/combined_mask.nii.gz"
fslmaths $csf_file -add $wm_file -add $gm_file $combined_mask
mri_convert "$BC/combined_mask.nii.gz" "$BC/combined_mask.nii"

# Check if the combined mask was created successfully
if [ -f $combined_mask ]; then
    echo "File ${combined_mask##*/} exists. Part 1 is all done! Please manually check this."
else
    echo "File ${combined_mask##*/} does not exist. Something went wrong with adding the CSF, GM, bone, other, and WM together!"
    exit 1
fi
