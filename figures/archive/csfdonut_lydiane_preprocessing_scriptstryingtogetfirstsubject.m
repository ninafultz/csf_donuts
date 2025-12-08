% csf donut protocol for t2 and csf mobility mapping
% nina fultz december 2024
% n.e.fultz@lumc.nl

%% to do:
% 1) automate t2 registration - might be doing compressed sense to make it
% full brain
% 2) automate angiogram registration - might be doing compressed sense to make it
% full brain
% 3) finish plotting functions at the end 

%% goals:
clear
clc
%%
% defining paths 
project_directory = '/exports/gorter-hpc/users/ninafultz/'
project_name      = 'csfdonuts_lydiane'
subject_code      = '20201016_Reconstruction'

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
mhdDir            = fullfile(subjPath, 'mhd');

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

%% running biasfield correction 

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

%% loading B0 mhd files 

% Specify the directory containing .mhd files
cd(mhdDir);

% Search for .mhd files matching the pattern
filePattern = 'Scan*_meanPhases_T2prep.mhd';
fileList = dir(filePattern);

% Check if any file matches the pattern
if isempty(fileList)
    error('No files matching the pattern "%s" found in the directory "%s".', filePattern, mhdDir);
end

% Loop through all matching files
for k = 1:length(fileList)
    mhdFile = fileList(k).name;
    fprintf('Processing file: %s\n', mhdFile);
    
    % Read metadata and image data
    info = metaImageInfo(mhdFile);
    imageData = metaImageRead(info);
    
    % Perform operations with the imageData (e.g., visualize, save, etc.)
    % Example: Display metadata and dimensions of the loaded image
    disp(info);
    fprintf('Image dimensions: %s\n', mat2str(size(imageData)));
    
    % Optional visualization or save
    % imshow3D(imageData); % Uncomment for 3D visualization if applicable
end


disp('converting B0 mhd file to niftis...');
B0_to_niftis(subjPath, imageData);

%% 

% 1) convert ADC and FA maps to niftis
disp('converting ADC and FA maps to niftis...');
ADCandFAmaps_to_niftis(subjPath);


% % fixing b0 scans
% disp('B0 scans into correct orientation...');
% b0_segmentation(project_directory, project_name, subject_code, scripts);

disp('Running elastix registration...');

fixed_image  = fullfile(regDir, 'B0_properOrientation.nii');  % Path to the fixed image
output_dir   = fullfile(subjPath, 'reoriented');
param_file   = fullfile(targetDir, 'par.glymphBONN.txt');  % Parameter file for Elastix

% Format the Elastix command string
cd(targetDir);
elastix_command = sprintf('./running_elastix.sh -f %s -m %s -o %s -p %s -n %s', ...
    fixed_image, fullfile(adc,'ADC_cardiacThres50.nii'), output_dir, ...
    param_file, 'ADC_cardiacThres50_to_B0_properOrientation');

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
%% registration elastix for CSF-STREAM space, ADC, FA, and original T1

disp('Running elastix registration...');

fixed_image  = fullfile(regDir, 'B0_properOrientation.nii');  % Path to the fixed image
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
    
    
    %% making combined mask - if you do the registered version youre going ...
    %%to get signal outside of the brain, so be careful
    
disp('Running biasfield correction on registered t1 to make combined mask...');

% Change to the scripts directory
cd(targetDir);

biasfield_command = sprintf('./running_biasfield_registeredt1.sh -n "%s"', ...
    subjPath);

% Run running_biasfield_job_t1_reg.sh
[status2, cmdout2] = system(biasfield_command);
if status2 == 0
    disp('running_biasfield_registeredt1.sh executed successfully!');
else
    disp('Error running_biasfield_registeredt1.sh:');
    disp(cmdout2);
end
    
%% reorientating and thresholding adc and fa maps

adc_and_fa_masking_reorientating(project_directory, project_name, subject_code);


%% **Donut Definition and Criteria:**
% 
% **Donuts in Relation to CSF Mobility:**
% 
% - **Arteries and Veins on CSF Mobility**:
%     - A "donut" must show a difference in ADC from the surrounding subarachnoid space (SAS) of at least 0.01 ADC units and have an absolute ADC value above 0.01.
%     - The donut can exist in the transversal, axial, or coronal plane.
%     - It does not need to encompass the entire circumference of the artery or vein before reaching the SAS wall. However, in at least one plane, there must be a measurable ADC difference between the donut and the SAS, and the difference should be visible in at least two slices.
%     - Donuts localized to one side of the artery or vein must be noted as lateralized donuts.
%     - If only a T1 is available, we will define CSF-mobility with the T1; we will look at MCA, ACA, and ACE points/bridging veins; MCA, ACA will be defined by T1 arteries, and ACE points will be defined as being in sagittal sinus and  run from through the SAS into the dura
% 
% **Vessel Criteria for Donuts:**
% 
% - The donut must be associated with a vein or an artery:
%     - Arteries: Defined via angiogram and have a T2* value of above 30
%        and are in clusters
%     - Veins: Defined via venogram with a T2* value below 30 ms and are in
%        clusters
% - All definitions will be confirmed by a neuroradiologist prior to publication.
% 
% **Additional Criteria:**
% 
% - The donut should show a steep drop-off (non-gradient transition) with the SAS.
% 
% **T2 Analysis of Donuts:**
% 
% - **T2 Donuts**:
%     - Should exhibit a T2 difference of approximately 200 ms relative to the surrounding SAS.
%     - Can be observed in the transversal, axial, or coronal plane.
%     - Similar to ADC donuts, T2 donuts do not need to encompass the entire side of the artery or vein before reaching the SAS wall, but at least one plane must show the T2 difference, and should be visible in at least two slices.
%     - T2 donuts that appear on only one side of the artery or vein must be noted as lateralized donuts.
% - T2 donuts may not necessarily correlate with CSF mobility but that should still be documented.

% **Vessel Criteria for Donuts:**
% 
% - The donut must be associated with a vein or an artery:
%     - Arteries: Defined via angiogram and have a T2* value of above 30
%        and are in clusters
%     - Veins: Defined via venogram with a T2* value below 30 ms and are in
%        clusters
% - All definitions will be confirmed by a neuroradiologist prior to publication.
% 
% **Additional Criteria:**
% 
% - Like ADC donuts, T2 donuts must show a steep drop-off (non-gradient transition) with the SAS

%% plotting 

csfmobility_rois.m

