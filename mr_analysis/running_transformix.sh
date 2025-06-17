#!/bin/bash

# how to write it out: ./running_transformix.sh -f fixed_image -o output_dir -t params -n outputname

#gets displayed when -h or --help is put in
display_usage(){
    echo "***************************************************************************************
Script for transformix in bash
*************************************************************************************** "
    echo Usage: ./running_transformix.sh -f fixed_image -o output_dir -t params -n outputname
       -f fixed_image 
       -o output_dir
       -t params
       -n outputname 
}

if [ $# -le 1 ]
then
    display_usage
    exit 1
fi

while getopts "f:o:t:n:" opts;
do
    case $opts in
        f) export FIXED_IMAGE=$OPTARG ;;
        o) export OUTPUT_DIR=$OPTARG ;;
        t) export PARAMS=$OPTARG ;;
        n) export NAME=$OPTARG ;;
    esac
done

module load neuroImaging/Elastix/5.0.0/gcc-7.4.0

echo transformix -in $FIXED_IMAGE -out $OUTPUT_DIR -tp $PARAMS
transformix -in $FIXED_IMAGE -out $OUTPUT_DIR -tp $PARAMS

echo mv $OUTPUT_DIR/result.nii $OUTPUT_DIR/$NAME
mv $OUTPUT_DIR/result.nii $OUTPUT_DIR/$NAME
