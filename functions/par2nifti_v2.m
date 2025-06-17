function par2nifti(subjPath, parDir);



%% loading par file 
cd(parDir)
[img_data, ~ ] = import_parrec_special_WT2_LH(1, '*'); % loads the raw data of all echoes (NOT YET MASKED!)
 

    FA_map_avg = flipud(img_data);
    img_data_flipped = permute(FA_map_avg,[3 1 2]);  % Flips the first dimension (top-to-bottom)
   % img_data_flipped = flip(FA_map_avg, 1);
    
    figure;
    imshow3Dfull(img_data_flipped(:,:,:)); % Adjust the intensity range as needed
    colorbar;
    title('T2* Map (ms)');
    xlabel('X');
    ylabel('Y');
    
%% 

        targetFile = fullfile('/exports/gorter-hpc/users/ninafultz/csfdonuts_lydiane/20191210_Reconstruction/anat/3dT1_0.9mm.nii');
        niftiInfo = niftiinfo(targetFile);

    % Update the NIfTI header information for this FA map
    niftiInfo.ImageSize = size(img_data_flipped);
    niftiInfo.Datatype  = class(img_data_flipped);  % Match the datatype to the FA map

    svdir = fullfile(subjPath, 'anat');
    output_nii_file = fullfile(svdir, '3dT1_0.9mm.nii'); % Define the output .nii file path
    % 
    % Save the T2 map as a NIfTI file
    niftiwrite(img_data_flipped, output_nii_file, niftiInfo);

end