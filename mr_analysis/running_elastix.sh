#!/bin/bash

# how to write it out: ./running_elastix.sh -f fixed_image -m moving_image -o output_dir -p param_file -n outputfilename

#gets displayed when -h or --help is put in
display_usage(){
    echo "***************************************************************************************     
Script for elastix in bash
*************************************************************************************** "
    echo Usage: ./running_elastix.sh -f fixed_image -m moving_image -o output_dir -p param_file -n nameofoutputfile       
       -f fixed_image
       -m moving_image
       -o output_dir
       -p param_file
       -n outputfile
}

if [ $# -le 1 ]
then
    display_usage
    exit 1
fi

while getopts "f:m:o:p:n:" opts;
do
    case $opts in
        f) export FIXED_IMAGE=$OPTARG ;;
        m) export MOVING_IMAGE=$OPTARG ;;
        o) export OUTPUT_DIR=$OPTARG ;;
        p) export PARAM_FILE=$OPTARG ;;
        n) export NAME=$OPTARG ;;
    esac
done

module load neuroImaging/Elastix/5.0.0/gcc-7.4.0

elastix -f $FIXED_IMAGE -m $MOVING_IMAGE -out $OUTPUT_DIR -p $PARAM_FILE
mv "$OUTPUT_DIR/result.0.nii" "$OUTPUT_DIR/${NAME}.nii"
mv "$OUTPUT_DIR/TransformParameters.0.txt" "$OUTPUT_DIR/${NAME}.txt"
