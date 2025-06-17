#!/bin/bash
#SBATCH --job-name=recons_pvs01        
#SBATCH --output=%x_%j.out
#SBATCH --mail-user="n.e.fultz@lumc.nl"
#SBATCH --mail-type="ALL"
#SBATCH --partition="gpu"
#SBATCH --time=48:00:00
#SBATCH --mem=40GB
#SBATCH --gres=gpu:1

## How to set the above SBATCH setting 
# job-name: indicate the name for this job (doesn't really matter, but is useful for your output file)
# output: this creates your script output file using the 'job-name' indicates above
# mail-user: indicate your emailadres so you receive updates about your job ID, when your job starts running, and when it finishes
# mail-type: leave on "ALL"
# partition: define partition, usually 'all' or 'gpu' (gpu when you do a gpu calculation). More info @https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI/pages/37519928/Partitions+on+SHARK        
# time: indicate the time you need for the script to run (in hh:mm:ss)
# mem: indicate the memory you need for the script to run
# gres: leave like it is. I think you can remove this line if you don't use the 'gpu' partition

module load neuroImaging/freesurfer/7.4.1 #Load the modules you need for this script to run e.g. freesurfer

echo "Script started at $(date)"

parallel mri_convert //exports/gorter-hpc/users/ninafultz/highres_pvs/{}/reg/r3dT1_0.9mm.nii //exports/gorter-hpc/users/ninafultz/highres_pvs/{}/reg/r3dT1_0.9mm.nii.gz ::: 20240810_PVS14

parallel SUBJECTS_DIR=//exports/gorter-hpc/users/ninafultz/highres_pvs/{} recon-all -all -subjid fs -parallel -i //exports/gorter-hpc/users/ninafultz/highres_pvs/{}/reg/r3dT1_0.9mm.nii.gz ::: 20240810_PVS14 

echo "Script finished at $(date)"
