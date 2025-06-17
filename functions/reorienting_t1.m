function reorienting_t1(subjPath);


anatFolder     = fullfile(subjPath, 'anat');
%% loading file 

    img_data = fullfile(anatFolder, '3dt1_0.9mm.nii');
    img_data = niftiread(img_data);

   
   ADC_map_avg = flipud(img_data);
    ADC_map_avg = permute(ADC_map_avg,[3 2 1]);  % Flips the first dimension (top-to-bottom)
    img_data_flipped = flip(ADC_map_avg, 1);
    img_data_rotated = rot90(img_data_flipped, -1);  % Use -1 for clockwise rotation

    figure;
    imshow3Dfull(img_data_flipped(:,:,:)); % Adjust the intensity range as needed
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