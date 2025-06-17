



addpath('/exports/gorter-hpc/users/ninafultz/scripts/spm12')
%% 

% Define project path and subject
project_path = '/exports/gorter-hpc/users/ninafultz/highres_pvs/';
subject = '20240307_PVS3';

% Construct the full path to the functional directory
func_dir = fullfile(project_path, subject, 'func');
anat_dir = fullfile(project_path, subject, 'anat');

%% 

% Load Reference Image
ref_image_path = fullfile(anat_dir, '3dT1_0.9mm.nii');
spm_image('Display', ref_image_path);

%% Load Image for Registration

img_to_register_path = fullfile(func_dir, 'merged_DelRec_-_pvs_70slices_ME.nii');
P = spm_select('FPList', func_dir, 'merged_DelRec_-_pvs_70slices_ME.nii');

%%  Select reference image

% Load Reference Image
ref_image_pattern = '^3dT1_0.9mm\.nii$';
VG = spm_select('FPList', anat_dir, ref_image_pattern);
%% 

% Manual Registration
% Prompt user to select the image to register (this can be adjusted as needed)
if isempty(P)
    error('No image found to register.');
end

% Perform the manual registration using GUI controls
params = spm_coreg(VG, P);
%% 

% Apply the transformation
MM = spm_matrix(params);
spm_reslice({VG, P}, struct('mean', false, 'which', 1, 'interp', 4));

% Save the transformation parameters
transformation_params_path = fullfile(func_dir, 'transformation_params.mat');
save(transformation_params_path, 'params');

% Display completion message
disp('Manual registration completed and transformation parameters saved.');


