% protocol

%% goals:
% 1) convert ADC and FA maps to niftis

T2map_to_niftis.m % converting ADC and FA maps to niftis
% register the 

% fixing b0 scans
b0_segmentation.m


% elastix
% module load neuroImaging/Elastix/5.0.0/gcc-7.4.0
% elastix -f B0_properOrientation.nii -m r3dT1_0.9mm_CSF.nii -out /exports/gorter-hpc/users/ninafultz/csf_donut/csfdonut01/reg -p par.glymphBONN.txt

adc_and_fa_masking_reorientating.m



%% 
venogram_to_phase.m %converts phase information 

venogram_combiningimages.m % combines echoes 


t2star_venogram.m % calculates t2* star values for venogram echoes 


t2star_venogram_thresholded.m


%% 

ROIs_plottingT2_andCSFmobility.m