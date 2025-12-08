% csf donut protocol for t2 and csf mobility mapping
% nina fultz december 2024
% n.e.fultz@lumc.nl

clear
clc

%% goals:

%%
% defining paths 
project_directory = '/exports/gorter-hpc/users/ninafultz/'
project_name      = 'csfdonuts_lydiane'
subject_code      = '20191029_Rec'

scripts           = fullfile(project_directory, 'scripts');
addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts, 'functions')));
addpath(genpath(fullfile(project_directory, project_name, subject_code)));


%% setting environments
env_vars = {
    'FREESURFER_HOME', '/share/software/neuroImaging/freesurfer/linux-centos8_x86_64-7.4.1', ...
    'SINGULARITY_HOME', '/share/software/container/singularity/3.9.6', ...
    'AFNI_HOME', '/share/software/neuroImaging/AFNI/21.3.07/gcc-8.3.1', ...
};

for i = 1:2:length(env_vars)
    setenv(env_vars{i}, env_vars{i+1});
    setenv('PATH', [getenv('PATH'), ':', env_vars{i+1}, '/bin']);
end

%% paths

% Define the command as a string
subjPath          = fullfile(project_directory, project_name, subject_code);
regDir            = fullfile(subjPath, 'reg');
parDir            = fullfile(subjPath, 'par');
anatDir           = fullfile(subjPath, 'anat');

% Construct the path
targetDir         = fullfile(scripts, project_name, 'mr_analysis');

% Change to the target directory
cd(targetDir);

%% converting T1s to niftis

% 1) converting t1s to niftis 
disp('converting anatomical T1s to niftis...');

% Change to the scripts directory
cd(targetDir);

anats_niftis = sprintf('./anats2nifti.sh -s "%s"', ...
    subjPath);

% Run running_biasfield_job_t1_reg.sh
[status2, cmdout2] = system(anats_niftis);
if status2 == 0
    disp('anats_nifti.sh executed successfully!');
else
    disp('Error anats_niftis:');
    disp(cmdout2);
end


   
%% running spm biasfield correction - will make GM, WM, CSF masks

disp('Running biasfield correction...');

% Change to the scripts directory
cd(targetDir);

biasfield_command = sprintf('./running_biasfield.sh -n "%s"', ...
    subjPath);

% Run running_biasfield_job_t1_reg.sh
[status2, cmdout2] = system(biasfield_command);
if status2 == 0
    disp('running_biasfield.sh executed successfully!');
else
    disp('Error running_biasfield.sh:');
    disp(cmdout2);
end

%% converting mhd to niftis

% Get the list of matching .mhd files
fileList = dir(fullfile(subjPath, 'mhd', 'Scan*_meanPhases_T2prep.mhd'));

% Ensure at least one file is found
if isempty(fileList)
    error('No matching files found: Scan*_meanPhases_T2prep.mhd');
end

% Construct the full path for the first matching file
referenceScanPath = fullfile(fileList(1).folder, fileList(1).name);

% Read the .mhd file
referenceScan = metaImageRead(referenceScanPath);

% Call mhd_to_niftis with the found file
mhd_to_niftis(subjPath, referenceScan);


%% convert ADC and FA maps to niftis
disp('converting ADC and FA maps to niftis...');
[ADC_map_avg, FA_map_avg] = ADCandFAmaps_to_niftis(subjPath);

%% registration elastix for CSF-STREAM space, ADC, FA, and original T1
% Predefined list of subjects to exclude
% will have to run the excluded subjects in itksnap, manually 
% make registration, apply with ANTS

excluded_subjects = {'20191022_Reconstruction' '20191112_Reconstruction' ...
    '20191029_Reconstruction'};  % List of excluded subjects

% Extract the subject name from the current path
[~, subject_name, ~] = fileparts(subjPath);

% % Check if the subject is in the excluded list
% if ismember(subject_name, excluded_subjects)
%     fprintf('Subject "%s" is in the exclusion list. go run SPM 
%     with same origins.\n', subject_name);
%     return;  % Exit the script
% end

disp('Running elastix registration...');

% % fixed_image  = fullfile(regDir, 'B0_properOrientation.nii');  % Path to the fixed image
fixed_image  = fullfile(regDir, 'B0_from_mhd.nii');  % Path to the fixed image

output_dir   = fullfile(subjPath, 'reoriented');
param_file   = fullfile(targetDir, 'par.glymphBONN.txt');  % Parameter file for Elastix

% Format the Elastix command string
cd(targetDir);
elastix_command = sprintf('./running_elastix.sh -f %s -m %s -o %s -p %s -n %s', ...
    fixed_image, fullfile(regDir,'3dT1_0.9mm_CSF.nii'), output_dir, ...
    param_file, '3dT1_0.9mm_CSF_to_B0_properOrientation');

% Run the Elastix command in the shell
[status, cmdout] = system(elastix_command);

if status == 0
    disp('elastix registration executed successfully!');
else
    disp('Error elastix registration:');
    disp(cmdout);
end 

    params          = fullfile(subjPath, 'reoriented', ...
        '3dT1_0.9mm_CSF_to_B0_properOrientation.txt');

    cd(targetDir);
    
    transformix_command = sprintf('./running_transformix.sh -f %s -o %s -t %s -n %s', ...
    fullfile(regDir,'3dT1_0.9mm.nii'), output_dir, params, ...
    '3dT1_0.9mm_to_B0_properOrientation.nii')


    % Run the Elastix command in the shell
    [status, cmdout] = system(transformix_command);

    if status == 0
        disp('transformix registration executed successfully!');
    else
        disp('Error elastix registration:');
        disp(cmdout);
    end
  
    
   % for 20191210 make sure to set origin of B0_properOrientation.nii to
   % B0_mhd.nii
    transformix_command = sprintf('./running_transformix.sh -f %s -o %s -t %s -n %s', ...
    fullfile(regDir,'3dT1_0.9mm_CSF.nii'), output_dir, params, ...
    '3dT1_0.9mm_CSF_to_B0_properOrientation.nii')


    % Run the Elastix command in the shell
    [status, cmdout] = system(transformix_command);

    if status == 0
        disp('transformix registration executed successfully!');
    else
        disp('Error elastix registration:');
        disp(cmdout);
    end
  
     transformix_command = sprintf('./running_transformix.sh -f %s -o %s -t %s -n %s', ...
    fullfile(regDir,'3dT1_0.9mm_CSF.nii'), output_dir, params, ...
    '3dT1_0.9mm_CSF_to_B0_properOrientation.nii')


    % Run the Elastix command in the shell
    [status, cmdout] = system(transformix_command);

    if status == 0
        disp('transformix registration executed successfully!');
    else
        disp('Error elastix registration:');
        disp(cmdout);
    end
   
    %% itksnap protocol for excluded subjects above
    
%1) open itksnap, click tools>registration
%2) moving image layer is t1
%3) run automatic (rigid, mutual information, 16x, 8x)
%4) load in registration when looking at file 

%% reorientating and thresholding adc and fa maps

adc_and_fa_masking_reorientating(subjPath, subject_code, ADC_map_avg, FA_map_avg);
