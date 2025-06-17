#!/bin/bash
# Script log to get data from scanner
# Nina Fultz January 2022

# how to write it out: ./get_data.sh -n dicoms -d /users/ninafultz/cluster_headache/{} -s dcm2niix

#gets displayed when -h or --help is put in
display_usage(){
    echo "*************************************************************************************** 
Script to retrieve data from scanner, convert to nifti and create minimal meta data files
*************************************************************************************** "
    echo "Usage: ./get_data.sh -n -d -s
           -n: Name of dicom directory - e.g. dicoms
           -d: Subject directory /autofs/cluster/mreg_project
           -s: Pathway to dcm2niix - you can download this from https://github.com/dangom/dcm2niix onto your cluster"
}

if [ $# -le 1 ]
then
    display_usage
    exit 1
fi

while getopts "n:d:s:" opts;
do
    case $opts in
        n) DICOM_DIR=$OPTARG ;;
        d) OUTPUT_DIR=$OPTARG ;;
        s) DCM2NIIX_DIR=$OPTARG ;;
    esac
done


# Convert dicoms to nifti and create sidecar JSON file

$DCM2NIIX_DIR -b y -f %p y -z y -o $OUTPUT_DIR/$DICOM_DIR/ $OUTPUT_DIR/$DICOM_DIR/
#$DCM2NIIX_DIR -b y -f -z y -o ${OUTPUT_DIR}/${DICOM_DIR}/ $OUTPUT_DIR/$DICOM_DIR/


############################# Start some preparation #################################

mkdir $OUTPUT_DIR/anat $OUTPUT_DIR/func $OUTPUT_DIR/info $OUTPUT_DIR/reg $OUTPUT_DIR/biasfield

#move stuff accordingly, add to this list
mv $OUTPUT_DIR/$DICOM_DIR/*T1* $OUTPUT_DIR/anat/
mv $OUTPUT_DIR/$DICOM_DIR/*3d* $OUTPUT_DIR/anat/
mv $OUTPUT_DIR/$DICOM_DIR/*pvs* $OUTPUT_DIR/func/

# Convert .nii.gz to .nii in anat directory
for file in $OUTPUT_DIR/anat/*.nii.gz; do
  if [ -f "$file" ]; then
    mri_convert "$file" "${file%.gz}"  # Convert .nii.gz to .nii
    echo "Converted $file to ${file%.gz}"
  fi
done

# Convert .nii.gz to .nii in func directory
for file in $OUTPUT_DIR/func/*.nii.gz; do
  if [ -f "$file" ]; then
    mri_convert "$file" "${file%.gz}"  # Convert .nii.gz to .nii
    echo "Converted $file to ${file%.gz}"
  fi
done

# Check if there are any .nii files in anat directory
INFO=$(ls $OUTPUT_DIR/anat/*.nii 2>/dev/null)
if [ -n "$INFO" ]; then
  echo "DICOM unpacking and parsing is all done! All done, have a lovely day!"
else
  echo "DICOM unpacking and parsing failed!"
fi
