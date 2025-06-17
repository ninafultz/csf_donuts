#!/bin/bash

# Script to do subarachnoid removal
# Usage: ./eeg_removal.sh -n <subject_name> -d <directory_path> -f <func_suffix>

display_usage(){
    echo "***************************************************************************************
script to do subarachnoid removal
***************************************************************************************"
    echo "Usage: ./eeg_removal.sh -n <subject_name> -d <directory_path> -f <func_suffix>"
    echo "   -n: Name of subject"
    echo "   -d: Directory of subject on Martinos Center cluster"
    echo "   -f: Suffix to be concatenated to output filenames"
}

if [ $# -le 1 ]; then
    display_usage
    exit 1
fi

while getopts "n:d:f:" opts; do
    case $opts in
        n) export SUBJECT=${OPTARG} ;;
        d) DIR=$OPTARG ;;
        f) FUNC=$OPTARG ;;
    esac
done

export EEG_REMOVAL=$DIR/$SUBJECT/csf_removal
mkdir -p $EEG_REMOVAL
echo $EEG_REMOVAL

#rsync -aP $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1_GM.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1_WM.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1_CSF.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1_bone.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1_other.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1.nii.gz $EEG_REMOVAL

# Ensure that functional and anatomical images have the same resolution
# Using FLIRT to register func to anat, assuming highres anatomical image is the reference
echo flirt -in $DIR/$SUBJECT/func/${FUNC}.nii.gz -ref $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1.nii.gz -out $EEG_REMOVAL/${FUNC}_resampled_functot1.nii.gz -omat $EEG_REMOVAL/${FUNC}_to_anat.mat


echo flirt -in $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1.nii.gz -ref $DIR/$SUBJECT/func/${FUNC}.nii.gz -out $EEG_REMOVAL/${FUNC}_resampled_t1tofunc.nii.gz -omat $EEG_REMOVAL/${FUNC}_to_anat.mat

# # Apply CSF mask to the resampled functional image
# fslmaths $EEG_REMOVAL/${FUNC}_resampled.nii.gz -mas $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1_CSF.nii.gz $EEG_REMOVAL/${FUNC}_noCSF.nii.gz

# # Apply bone mask to the CSF-masked functional image
# fslmaths $EEG_REMOVAL/${FUNC}_noCSF.nii.gz -mas $DIR/$SUBJECT/anat/Ppmr7t0847^X^^^_3dT1_0.9mm_5_1_bone.nii.gz $EEG_REMOVAL/${FUNC}_noCSF_nobone.nii.gz

