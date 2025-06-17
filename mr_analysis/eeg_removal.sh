#!/bin/bash

#will copy biascorrected to a new folder 
#how to write it out: ./eeg_removal.sh -n racsleep08 -d /autofs/cluster/ldl/nina/pet_eeg_fmri


#gets displayed when -h or --help is put in
display_usage(){
    echo "***************************************************************************************
script to do subarachnoid removal
***************************************************************************************"
    echo Usage: ./eeg_removal.sh -n -d -b
       -n: Name of subject
       -d: directory of subject on martinos center cluster
 }

if [ $# -le 1 ]
then
    display_usage
    exit 1
fi

while getopts "n:d:" opts;
do
    case $opts in
        n) export SUBJECT=${OPTARG} ;;
        d) DIR=$OPTARG ;;
    esac
done

export EEG_REMOVAL=$DIR/$SUBJECT/csf_removal
mkdir $EEG_REMOVAL
echo $EEG_REMOVAL

rsync -aP $DIR/$SUBJECT/anat/Ppmr7t0849^X^^^_3dT1_0.9mm_5_1_GM.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0849^X^^^_3dT1_0.9mm_5_1_WM.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0849^X^^^_3dT1_0.9mm_5_1_CSF.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0849^X^^^_3dT1_0.9mm_5_1_bone.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0849^X^^^_3dT1_0.9mm_5_1_other.nii.gz $DIR/$SUBJECT/anat/Ppmr7t0849^X^^^_3dT1_0.9mm_5_1.nii.gz $EEG_REMOVAL


