function adc_and_fa_masking_reorientating(subjPath, subject_code, ADC_map_avg, FA_map_avg);

% goal: convert adc and fa maps to niftis, create frangi filter on inverted
% image
% register t2 maps to the b0 

%% Paths
regDir         = fullfile(subjPath, 'reg');
fa             = fullfile(subjPath, 'fa');
adc            = fullfile(subjPath, 'adc');
reoriented     = fullfile(subjPath, 'reoriented');
% toolbox        = fullfile(project_directory, 'scripts', 'toolbox');
% 
% addpath(genpath(toolbox));



%% 
    mkdir(reoriented);
%     source          = fullfile(regDir,'B0_from_mhd.nii');
%     destination     = fullfile(reoriented,'B0_from_mhd.nii');
% 
%     % Copy the file
%     copyfile(source, destination);
%  
    
    b0 = niftiread([fullfile(reoriented,'B0_from_mhd.nii')]);

     % Define the switch block for subject-specific operations
    switch subject_code
%         case '20191029_Reconstruction'
%             threshold = 100;
%         case '20201008_Reconstruction'
%             threshold = 75;
%         case '20201014_Reconstruction'
%             threshold = 150;
%         case '20201016_Reconstruction'
%             threshold = 75;
%         case '20201019_Reconstruction'
%             threshold = 75;
%         case '20191022_Reconstruction'
%             threshold = 150;
        otherwise
            threshold = 150; % 75; 100; 125; 150
    end


    %% 
    
%     brain_mask = niftiread(fullfile(reoriented,'3dT1_0.9mm_combined_to_B0_properOrientation.nii'));
%     brain_mask = brain_mask > 0;
%     combined_mask = imclose(brain_mask,strel('sphere',3));
% %     
%     figure;
%     imshow3Dfull(brain_mask); % Adjust the intensity range as needed

    %% 
    
%     figure;
%     imshow3Dfull(ADC, [0 0.05]); % Adjust the intensity range as needed
% 
%     figure;
%     imshow3Dfull(FA, [0 0.05]); % Adjust the intensity range as needed
% 
%     figure;
%     imshow3Dfull(combined_mask, [0 1]); % Adjust the intensity range as needed

    %% masking brain for visualization


% Display the combined mask for verification
% figure;
% imshow3Dfull(combined_mask); % Display to verify the combined mask
% Resample the mask to match the dimensions of the FA/ADC map

% combined_mask_resized = imresize3(combined_mask, size(ADC_map_avg)); % Use 'nearest' for binary masks

% figure;
% imshow3Dfull(combined_mask_resized); % Adjust the intensity range as needed
% 
% % Ensure the mask is still binary after resizing
% combined_mask_resized = (combined_mask_resized > 0);
% combined_mask_resized_single = single(combined_mask_resized);
% 
% % Apply the resized mask to the FA and ADC maps
% masked_FA = FA_map_avg .* combined_mask_resized_single;
% masked_ADC = ADC_map_avg .* combined_mask_resized_single;
%% 

% figure;
% imshow3Dfull(adc, [0 0.05]);
%b0 = b0(:, :, 1:381);

masked_ADC_b0 = ADC_map_avg .* (b0>threshold);
masked_FA_b0 = FA_map_avg .* (b0>threshold);
b0_thresholded = b0>threshold;
b0_thresholded_single = single(b0_thresholded);
%Display the results
% figure;
% imshow3Dfull(masked_ADC_b0, [0 0.05]) %, [0 0.05]); 


% % 
% figure;
% imshow3Dfull(masked_FA, [0 0.05]);
%% saving adc, fa, and masked images in same image space 

    adc = ADC_map_avg;
    fa = FA_map_avg;
    
    cd(reoriented)
    img = fullfile(reoriented,'B0_from_mhd.nii');
    
    voxelSize = [0.45 0.45 0.45];
    origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
    datatype = 16;
%     newnii= make_nii(adc, voxelSize, origin, datatype);
%     svdir = fullfile(reoriented);
%     save_nii(newnii,sprintf('ADC_properorientation.nii'), svdir)
% 
%     newnii= make_nii(fa, voxelSize, origin, datatype);
%     origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
%     svdir = fullfile(reoriented);
%     save_nii(newnii,sprintf('FA_properorientation.nii'), svdir)

    newnii= make_nii(b0_thresholded_single, voxelSize, origin, datatype);
    origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
    svdir = fullfile(reoriented);
    save_nii(newnii, sprintf('B0_from_mhd_thr%.4f.nii', threshold), svdir);

%     newnii= make_nii(masked_ADC, voxelSize, origin, datatype);
%     origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
%     svdir = fullfile(reoriented);
%     save_nii(newnii,sprintf('maskedADC_mhd.nii'), svdir)
%     
%     newnii= make_nii(masked_FA, voxelSize, origin, datatype);
%     origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
%     svdir = fullfile(reoriented);
%     save_nii(newnii,sprintf('maskedFA_mhd.nii'), svdir)

%     Save masked_ADC_b0 with threshold in the name
    newnii = make_nii(masked_ADC_b0, voxelSize, origin, datatype);
    origin = [round(size(adc,1)/2), round(size(adc,2)/2), round(size(adc,3)/2)];
    svdir = fullfile(reoriented);
    save_nii(newnii, sprintf('masked_b0_ADC_mhd_thr%.4f.nii', threshold), svdir);

    % Save masked_FA with threshold in the name
    newnii = make_nii(masked_FA_b0, voxelSize, origin, datatype);
    origin = [round(size(adc,1)/2), round(size(adc,2)/2), round(size(adc,3)/2)];
    svdir = fullfile(reoriented);
    save_nii(newnii, sprintf('maskedFA_mhd_thr%.4f.nii', threshold), svdir);
end