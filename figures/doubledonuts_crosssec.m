%% csf mobility all subjects

%% purpose
% 1) plot average of ADC as it moves from 0 for different cross sectionals
% 2) bar plots for ratings
% 3) statistical comparison 
clear;

% Define project parameters
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name = 'csfdonuts_lydiane';
 
%fig = 'donut02_cross_sec';  % example value: 'mca_cross_sec', 'donut01_cross_sec'
fig = 'doubledonut_cross_sec'

if strcmp(fig, 'doubledonut_cross_sec')
    subject_list = dir(fullfile(project_directory, project_name, ...
        '*20201014_Reconstruction*'));
    roi_patterns = {'20201014_doubldonutM2'} % % use adc_map thr150
    adc_map = 'csf_mobility.nii';
else
    warning('Unknown figure type: %s', fig);
end
% Define voxel size in mm
voxel_size = 0.45; % Assuming isotropic voxel size

%% 

addpath(genpath(fullfile(project_directory, 'scripts', ...
    project_name, 'functions')));

%% plotting individual subjects

plotDonutMeansB0Meanplottedv3(project_directory, project_name, ...
    subject_list, roi_patterns, voxel_size, adc_map);

