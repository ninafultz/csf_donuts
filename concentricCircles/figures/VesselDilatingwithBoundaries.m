% csf donut protocol for CAA patients 
% nina fultz january 2026
% n.e.fultz@lumc.nl

%% goals:
% output: in your CCDir you are going to get a nifti called: 'vesseltoCheck_ALL.nii'
% you will have to manually change that vessel mask, and then also split it
% into M1, M2, and ACA sections. 
% name these files: 'vesseltoCheck_' ROI '_manual.nii' in CCDir directory;

clear
clc
%%
% defining paths 
project_directory = 'R:\- Gorter\- Personal folders\Fultz, N\';
project_name      = 'csfdonuts_lydiane'
scripts           = fullfile(project_directory, 'scripts', project_name);

%%params
voxSize = 0.45; % voxel size mm
maxDist = 10; % distance away from vessel - mm 
binWidth = 0.45; % bins - probs same as your voxsize - mm

addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts)));

subject_list = {
'20191022_Reconstruction'
'20201020_Reconstruction'
'20201111_Reconstruction'
'20191210_Reconstruction'
'20201019_Reconstruction'
'20201110_Reconstruction'};

for k = 1:numel(subject_list)
        
        subject_code = subject_list{k}
        %% paths
        
        subjPath                 = fullfile(project_directory, project_name, subject_code);
        reorientedDir            = fullfile(subjPath, 'reoriented');
        regDir                   = fullfile(subjPath, 'reg');
        CCDir                   = fullfile(subjPath, '\', 'makingVessels');
        ROIsDir                   = fullfile(subjPath, '\', 'ROIs');
        mkdir(CCDir);
        cd(reorientedDir);
        MRScriptsDir             = fullfile(scripts, 'mr_analysis');
        addpath(genpath(fullfile(project_directory, project_name, subject_code)));
        
        %% loading t1, csf mobility 
        % Default filenames
            t1File  = '3dT1_0.9mm_to_B0_properOrientation.nii';
            adcFile = 'masked_b0_ADC_mhd_thr150.0000.nii';
            b0File  = 'B0_from_mhd.nii';
            
            
            switch subject_code
                case '20191112_Reconstruction'
                    t1File = 't1_moving_registered.nii.gz';
            
                case {'20201008_Reconstruction', '20201016_Reconstruction', '20201014_Reconstruction'}
                    t1File = 'r3dT1_0.9mm_to_B0_properOrientation.nii'; % rT1
            
                case '20191029_Rec'
                    t1File  = '3dT1_ITKSNAP.nii';
                    adcFile = 'ADC_ITKSNAP.nii';
            end
            
            % Load volumes
            V   = spm_vol(t1File);      % USE BIASFIELD CORRECTED SCAN
            t1  = spm_read_vols(V);
            
            adcV = spm_vol(adcFile);
            adc  = spm_read_vols(adcV);
            info = niftiinfo(adcFile);
            
            b0   = spm_vol(b0File);
            b0_seg = spm_read_vols(b0);
        
        
        cd(CCDir);
        t1vessel = spm_vol('t1_vessel.nii');
        t1vesselmask = spm_read_vols(t1vessel);
        
       t1mask_inROI = t1vesselmask .* (adc == 0); % making sure there is no overlap.

        % figure;
        % imshow3Dfull(t1mask_inROI); 
        vessel = t1mask_inROI;

        %         cd(CCDir);
        %         niftiwrite(t1mask_inROI, 'vessel_roi_noOverlap.nii');
        % % 
        % 
        
        %% combing adc and vessel mask, and the closing the gaps, 
        % and then dilating the adc; you will then reapply the vessel mask
        % and dilate until the newly formed adc/vessel combination edge.
        % you then get rid of any voxels that overlap with adc; this will
        % give you pretty large vessel filling the adc map
                  
        adc_mask = adc > 0;
        vessel_mask = vessel > 0; 
        
        combined = adc_mask | vessel_mask;
        combined_closed = imclose(combined, strel('sphere', 3)); % bridge small gaps
        combined_filled = imfill(combined_closed, 'holes');


        % figure;
        % imshow3Dfull(combined_filled); 



                for iter = 1:3
                    expanded = imdilate(vessel, strel('sphere', iter));
                    vesselExpanded = expanded .* (combined_filled > 0);
                end
        x = vesselExpanded & (adc == 0);

        % figure;
        % imshow3Dfull(x); 
        % 
        % 
        % figure;
        % imshow3Dfull(filledVessel); 

                boundarySingle = single(x);
                cd(CCDir);
                niftiwrite(boundarySingle, ['vesseltoCheck_ALL.nii']);

                vesselsingle = single(adc);
                niftiwrite(vesselsingle, 'csf_mobility.nii');
            
                vesselsingle = single(t1);
                niftiwrite(vesselsingle, 't1.nii');
            
                vesselsingle = single(b0_seg);
                niftiwrite(vesselsingle, 'b0.nii');
end
