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

    voxelSize = [0.9 0.9 0.9];
    datatype = 16;
    
    origin = [round(size(img_data_flipped,1)/2), round(size(img_data_flipped,2)/2),...
        round(size(img_data_flipped,3)/2)];
    newnii = make_nii(img_data_flipped, voxelSize, origin, datatype);
    svdir = fullfile(subjPath, 'anat');
    cd(svdir);
    save_nii(newnii, '3dT1_0.9mm.nii');

end