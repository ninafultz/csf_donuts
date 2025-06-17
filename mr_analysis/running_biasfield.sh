#!/bin/bash

# how to write it out: ./running_biasfield_job_t1_reg.sh -n $SUBJECT

#gets displayed when -h or --help is put in
display_usage(){
    echo "***************************************************************************************
Script for biasfield correction
*************************************************************************************** "
    echo Usage: ./registration.sh -n
       -n: Name of subject
}

if [ $# -le 1 ]
then
    display_usage
    exit 1
fi

while getopts "n:" opts;
do
    case $opts in
        n) export SUBJECT_NAME=$OPTARG ;;
    esac
done


module load neuroImaging/freesurfer/7.4.1 #Load the modules you need for this script to run e.g. freesurfer
module load container/singularity/3.9.6/gcc.8.3.1
module load neuroImaging/AFNI/21.3.07/gcc-8.3.1

./biasfieldcorrection --with-segmentation --overwrite $SUBJECT_NAME/reg/3dT1_0.9mm.nii $SUBJECT_NAME/reg/3dT1_0.9mm_bc.nii
