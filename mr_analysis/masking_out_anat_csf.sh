#!/bin/bash

# Usage information
display_usage() {
    echo "***************************************************************************************"
    echo "Script to take bias corrected, eroded, skull mask and apply it to MEMPRAGE to remove EEG artifact."
    echo "***************************************************************************************"
    echo "Usage: ./masking_out_eeg.sh -n SUBJECT_NAME -d DIRECTORY"
    echo "   -n: Name of subject"
    echo "   -d: Directory containing the subject's data"
    echo "   -c: manual CSF PVS mask"
    echo "Example: ./masking_out_eeg.sh -n racsleep08 -d /path/to/data -c CSF.nii.gz"       
}

# Check if the correct number of arguments is provided
if [ $# -le 3 ]; then
    display_usage
    exit 1
fi

# Parse command line arguments
while getopts "n:d:c:" opts; do
    case $opts in
        n) SUBJECT=$OPTARG ;;
        d) DIR=$OPTARG ;;
        c) CSF=$OPTARG ;;
        *) display_usage
           exit 1 ;;
    esac
done

# Set environment variables
export BC="$DIR/$SUBJECT/biasfield"
export FUNC="$DIR/$SUBJECT/func"

# Find the relevant files
mergedecho_file=$(find $BC -name 'combinedEchoes.nii' -print -quit)
csf_file=$(find $BC -name '*e2a_CSF_dilated.nii.gz' -print -quit)
gm_file=$(find $BC -name '*e1a_GM.nii.gz' -print -quit)
wm_file=$(find $BC -name '*e1a_WM.nii.gz' -print -quit)
bone_file=$(find $BC -name '*e1a_bone.nii.gz' -print -quit)
other_file=$(find $BC -name '*e1a_other.nii.gz' -print -quit)

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
mri_convert "$BC/combined_mask.nii.gz" "$BC/combined_mask.nii"
fslmaths $bone_file -add $other_file $combined_mask

#gm wm mask where you subtract the dilated csf, need it from the combined echo brain,

# Check if the combined mask was created successfully
if [ -f $combined_mask ]; then
    echo "File ${combined_mask##*/} exists. Part 1 is all done! Please manually check this."
else
    echo "File ${combined_mask##*/} does not exist. Something went wrong with 
adding the CSF, GM, bone, other, and WM together!"
    exit 1
fi


# CSF PVS mask
output_PVS="$BC/CSF_PVS.nii.gz"
echo fslmaths $mergedecho_file -mas $BC/$CSF $output_PVS
fslmaths $mergedecho_file -mas $BC/$CSF $output_PVS

 # Invert the CSF mask
fslmaths $csf_file -binv ${csf_file}_inv.nii.gz

# Apply the inverted mask to the merged echo file
output_noCSF="$BC/merged_noCSF_new.nii.gz"
output="$BC/merged_noCSFnoother_new.nii.gz"
fslmaths $mergedecho_file -mas ${csf_file}_inv.nii.gz $output_noCSF
fslmaths $combined_mask -binv ${combined_mask}_inv.nii.gz
fslmaths $output_noCSF -mas ${combined_mask}_inv.nii.gz $output



# Apply the GM mask to the functional image
output_GM="$BC/merged_GM.nii.gz"
#output_CSF="$BC/combined_gmwm_minusCSF.nii.gz"
#output_noCSF="$BC/merged_noCSF.nii.gz"
gmwm="$BC/merged_GMWM.nii.gz"
#fslmaths $mergedecho_file -sub $csf_file $output_noCSF
fslmaths $gm_file -add $wm_file $gmwm
fslmaths $output -mas $gmwm $output_GM
#fslmaths $output_GM -sub $csf_file $output_CSF
mri_convert "$BC/merged_GMWM.nii.gz" "$BC/merged_GMWM.nii"
#mri_convert "$BC/combined_gmwm_minusCSF.nii.gz" "$BC/combined_gmwm_minusCSF.nii"


# Check if the GM masked image was created successfully
if [ -f $output_noCSF ]; then
    echo "File ${$output_noCSF##*/} exists. Part 2 (CSF removed from MEMPRAGE) is all done! Please manually check this."
else
    echo "File ${$output_noCSF##*/} does not exist. Something went wrong with 
applying the GM mask to the MEMPRAGE!"
    exit 1
end
