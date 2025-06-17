%% elastix registration 

clear;

% goal: to register t1s to b0
% register t2 maps to the b0 
%% Define project directory and subject code
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name      = 'csf_donut';
subject_code      = 'csfdonut02_20191022';

%% Paths
t2maps_path    = fullfile(project_directory, project_name, subject_code, 't2_maps');
regDir         = fullfile(project_directory, project_name, subject_code, 'reg');
fa             = fullfile(project_directory, project_name, subject_code, 'fa');
adc            = fullfile(project_directory, project_name, subject_code, 'adc');

% Load the reference NIfTI file to get header information (can be any existing NIfTI file)
echo1File = fullfile(regDir, 'pp_22102019_1411141_5_1_3dt1_0.9mmV4_CSF.nii');
niftiInfo = niftiinfo(echo1File);  % Load the NIfTI header information


