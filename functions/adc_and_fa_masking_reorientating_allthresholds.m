function adc_and_fa_masking_reorientating(subjPath, subject_code, ADC_map_avg, FA_map_avg);

% goal: convert adc and fa maps to niftis, create frangi filter on inverted
% image
% register t2 maps to the b0 

%% Paths
regDir         = fullfile(subjPath, 'reg');
fa             = fullfile(subjPath, 'fa');
adc            = fullfile(subjPath, 'adc');
reoriented     = fullfile(subjPath, 'reoriented');


%% 
    mkdir(reoriented);
    b0 = niftiread([fullfile(reoriented,'B0_from_mhd.nii')]);

     % Define the switch block for subject-specific operations
    switch subject_code
        otherwise
            threshold = 175; % 75; 100; 125; 150; 175; 200; 210
    end


    %% masking brain for visualization

masked_ADC_b0 = ADC_map_avg .* (b0>threshold);
masked_FA_b0 = FA_map_avg .* (b0>threshold);
b0_thresholded = b0>threshold;
b0_thresholded_single = single(b0_thresholded);

%% saving adc, fa, and masked images in same image space 

    adc = ADC_map_avg;
    fa = FA_map_avg;
    
    cd(reoriented)
    img = fullfile(reoriented,'B0_from_mhd.nii');
    
    voxelSize = [0.45 0.45 0.45];
    origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
    datatype = 16;

    newnii= make_nii(b0_thresholded_single, voxelSize, origin, datatype);
    origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
    svdir = fullfile(reoriented);
    save_nii(newnii, sprintf('B0_from_mhd_thr%.4f.nii', threshold), svdir);

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