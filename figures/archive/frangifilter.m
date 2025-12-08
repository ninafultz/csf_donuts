clear

% applying frangi filter to inverted b0 scan 

%% Define project directory and subject code
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name      = 'csf_donut';
subject_code      = 'csfdonut01';

%% Paths
regDir         = fullfile(project_directory, project_name, subject_code, 'reg');
fa             = fullfile(project_directory, project_name, subject_code, 'fa');
adc            = fullfile(project_directory, project_name, subject_code, 'adc');
reoriented     = fullfile(project_directory, project_name, subject_code, 'reoriented');
biasfield      = fullfile(project_directory, project_name, subject_code, 'biasfield');
toolbox        = fullfile(project_directory, 'scripts', 'toolbox');

addpath(genpath(toolbox));


% Load your image (replace 'csf_image.nii' with your actual file)
nii = niftiread('bo_inverted_properorientation.nii'); % Requires NIfTI tools if loading NIfTI
csf_image = nii; % Extract image data


%% Display original and inverted images

    figure;
    imshow3Dfull(csf_image, [0 1]); % Adjust the intensity range as needed
       
        %% apply frangi
        options.FrangiScaleRange = [0.6 1];
        options.FrangiScaleRatio = 0.2;
        options.FrangiAlpha = 0.5;
        options.BlackWhite = 1;
        options.FrangiC = 300;

        
        %% 
        cd('/exports/gorter-hpc/users/ninafultz/scripts/toolbox/frangi_filter_version2a')
        mex eig3volume.c
        
        frangiFilter = FrangiFilter3D(inverted_image,options);
        
       
        
        figure, imshow3Dfull(frangiFilter, [0 1.746394246993077e-07])
        
        binaryFrangi = frangiFilter > 0;

% Display the binary result
figure, imshow3Dfull(binaryFrangi);
singlebinaryFrangi = single(binaryFrangi);
        %% 
        
        % Define the output filename

cd(reoriented)
img = fullfile(reoriented,'B0_properOrientation.nii');

voxelSize = [0.45 0.45 0.45];
origin = [round(size(adc,1)/2) round(size(adc,2)/2) round(size(adc,3)/2)];
datatype = 16;
newnii= make_nii(singlebinaryFrangi, voxelSize, origin, datatype);
svdir = fullfile(reoriented);
save_nii(newnii,sprintf('frangiFilter.nii'), svdir)

%% 


% Assuming `csf_image` and `frangi_result` are already computed and are the same size
figure;

% Normalize images for display purposes (if needed)
csf_image_norm = (csf_image - min(csf_image(:))) / (max(csf_image(:)) - min(csf_image(:)));
frangi_result_norm = (frangiFilter - min(frangiFilter(:))) / (max(frangiFilter(:)) - min(frangiFilter(:)));


% Create an RGB version of the CSF image for color overlay
csf_rgb = repmat(csf_image_norm, [1, 1, 1, 3]); % For 3D data, keep the 4th dimension

% Add the Frangi filter as a blue channel overlay
overlay_image = csf_rgb;
overlay_image(:, :, :, 3) = overlay_image(:, :, :, 3) + frangi_result_norm; % Add Frangi filter to blue channel

% % Clip values to avoid overflow
% overlay_image(overlay_image > 1) = 1;

% Display the result
imshow3Dfull(overlay_image);
title('Overlay of CSF Image with Frangi Filter in Blue');
%% 

% Assuming `csf_image` and `frangi_result` are already computed and are the same size
figure;

% Normalize images for display purposes (if needed)
csf_image_norm = (csf_image - min(csf_image(:))) / (max(csf_image(:)) - min(csf_image(:)));

% Create an RGB version of the CSF image for color overlay
csf_rgb = repmat(csf_image_norm, [1, 1, 1, 3]); % For 3D data, keep the 4th dimension

% Add the Frangi filter as a red channel overlay
overlay_image = csf_rgb;
overlay_image(:, :, :, 1) = overlay_image(:, :, :, 1) + frangiFilter; % Add Frangi filter to red channel

% Clip values to avoid overflow
overlay_image(overlay_image > 1) = 0.5;
% Display the result
imshow3Dfull(overlay_image);
title('Overlay of CSF Image with Frangi Filter in Bright Red');

