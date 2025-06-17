#!/bin/bash

# how to write it out: ./registration.sh -n inkref_07_cap -d /home/nefultz/highres_pvs
# nina fultz july 2024

#gets displayed when -h or --help is put in
display_usage(){
    echo "***************************************************************************************
Script for registration for high res pvs project
*************************************************************************************** "
    echo Usage: ./registration.sh -n -d
       -n: Name of subject
       -d: Home directory
}

if [ $# -le 1 ]
then
    display_usage
    exit 1
fi

while getopts "n:d:" opts;
do
    case $opts in
        n) export SUBJECT_NAME=$OPTARG ;;
        d) export PROJ_PATH=$OPTARG ;;
    esac
done


            scan=$PROJ_PATH/$SUBJECT_NAME
            if [ -d "${scan}" ]; then

                echo "1) scan directory $scan exists."

                export REG=$scan/reg
                mkdir $REG
                echo " 2) reg directory $REG exists."
                echo "3) cding to: $scan/func/"

                cd $scan/func/

                IMAGE_NAME=($(find $scan/func/ -name '*.nii' -type f))
                for i in "${IMAGE_NAME[@]}"; do
                    export SUBJECTS_DIR=$scan/
                    echo "$SUBJECTS_DIR"

                    base_file_name=`basename ${i} .nii`
                    echo $base_file_name
                    echo "4) the func image is: $base_file_name"

                    fname=`$FSLDIR/bin/remove_ext $base_file_name`; # remove extension

                    if [ ! -f "$REG/${fname}_reg.dat" ]; then
                            mri_convert ${fname}.nii.gz ${fname}.nii
                            bbregister --s fs/ --mov ${fname}.nii --reg $REG/${fname}_reg.dat --t1
                         else
                            echo "registration already exists: ${fname}_reg.dat"
                    fi
                done
fi
