%% csf mobility all subjects

%% purpose
% 1) plot average of ADC as it moves from 0 
% 2) plot average of FA as it moves from 0
% 3) violinplot of ADC average as steps
% 4) violintplot of FA average as steps
% 5) statistical comparison 
clear;

% Define project parameters
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name = 'csfdonuts_lydiane';
 
fig = 'donut02_cross_sec';  % example value

if strcmp(fig, 'mca_cross_sec')
    subject_list = dir(fullfile(project_directory, project_name, '*20191112_Reconstruction*'));
    roi_patterns = {'masked_b0_ADC_mhd_thr100.0000_MCA_roundseg'}
elseif strcmp(fig, 'aca_cross_sec')
    subject_list = dir(fullfile(project_directory, project_name, '*20191210_Reconstruction*'));
    %roi_patterns = {'masked_b0_ADC_mhd_thr100.0000_ACA'};
    roi_patterns = {'ACA_trapped'};
    adc_map = 'masked_b0_ADC_mhd_thr150.0000.nii';
elseif strcmp(fig, 'ica_cross_sec')
    subject_list = dir(fullfile(project_directory, project_name, '*20201019_Reconstruction*'));
    roi_patterns = {'masked_b0_ADC_mhd_thr150.0000_ICA'} % 20201019_Reconstruction ICA
    adc_map      = 'masked_b0_ADC_mhd_thr150.0000.nii';
elseif strcmp(fig, 'donut01_cross_sec')
    subject_list = dir(fullfile(project_directory, project_name, '*20201014_Reconstruction*'));
    roi_patterns = {'20201014_312_316_166_M2_roundseg'} % 'masked_b0_ADC_mhd_thr100.0000.nii'
    adc_map = 'masked_b0_ADC_mhd_thr100.0000.nii';
elseif strcmp(fig, 'donut02_cross_sec')
    subject_list = dir(fullfile(project_directory, project_name, '*20201014_Reconstruction*'));
    roi_patterns = {'20201014_134_340_140_M2_roundseg'} % % use adc_map thr150
    adc_map = 'masked_b0_ADC_mhd_thr150.0000.nii';
else
    warning('Unknown figure type: %s', fig);
end

% Define voxel size in mm
voxel_size = 0.45; % Assuming isotropic voxel size

%% 

addpath(genpath(fullfile(project_directory, 'scripts', ...
    project_name, 'functions')));

%% plotting individual subjects

plotDonutMeansB0Meanplottedv2(project_directory, project_name, ...
    subject_list, roi_patterns, voxel_size, adc_map);

%% box plots percentage 

cd (fullfile(project_directory, ...
    project_name, 'donut_ratings'))
%% A1

filename = 'A1_rating.xlsx';  % Replace with actual CSV file
col_right = 'a1Right';  % Column name for right A1
col_left = 'a1Left';    % Column name for left A1
categories = {'eye donut', 'full donut',  'high csf mobility', 'compartment', 'no donut'};

plotDonutBarPlots(filename, col_right, col_left, categories)
%% M1

filename = 'M1_rating.xlsx';  % Replace with actual CSV file
col_right = 'm1Right';  % Column name for right A1
col_left = 'm1Left';    % Column name for left A1

plotDonutBarPlots(filename, col_right, col_left, categories)

%% ICA

filename = 'ICA_rating.xlsx';  % Replace with actual CSV file
col_right = 'ICARight';  % Column name for right A1
col_left = 'ICALeft';    % Column name for left A1

plotDonutBarPlots(filename, col_right, col_left, categories)

%% peripheral arteries percentage 

filename = 'M2_onwardsrating.xlsx';  % Replace with actual Excel file
col_right = 'm2Onwards_Right';  % Column name for right ratings
col_left = 'm2Onwards_Left';    % Column name for left ratings


plotDonutM2onwardsrating(filename, col_right, col_left, categories)


