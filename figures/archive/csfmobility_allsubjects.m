%% csf mobility all subjects

%% purpose
% 1) plot average of ADC as it moves from 0 
% 2) plot average of FA as it moves from 0
% 3) violinplot of ADC average as steps
% 4) violintplot of FA average as steps
% 5) statistical comparison 

%% to do
% add CI, stats, clean up cross sectional, finish bad subjects, finish
% violin plots

% Define project parameters
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name = 'csfdonuts_lydiane';
subject_list = dir(fullfile(project_directory, project_name, '*Reconstruction*'));

% Define voxel size in mm
voxel_size = 0.45; % Assuming isotropic voxel size

% Initialize data storage for across-subject values
% roi_patterns = {'artery', 'acepoint', 'm1_longdonut', 'a1_longdonut',...
%     'a2_longdonut', 'a3_longdonut', 'vein', 'm1_shortnodonut', 'a1_shortnodonut',...
%     'a2_shortnodonut', 'a3_shortnodonut'};
roi_patterns = {'MCA_longdonut', 'ACA_longdonut', 'ICA_compartment'};

%% 

addpath(genpath(fullfile(project_directory, 'scripts', ...
    project_name, 'functions')));

%% plotting individual subjects

plotDonutInvidualSubjects(project_directory, project_name, ...
    subject_list, roi_patterns, voxel_size);


%% plot means and individual subjects in back

plotDonutMeans(project_directory, project_name, subject_list, ...
    roi_patterns, voxel_size);

%% 

plotDonutMeansFA(project_directory, project_name, subject_list, ...
    roi_patterns, voxel_size);

%% with all b0 lines and average 

plotDonutMeansB0plotted(project_directory, project_name, ...
    subject_list, roi_patterns, voxel_size);

%% with just b0 mean and adc

plotDonutMeansB0Meanplotted(project_directory, project_name, ...
    subject_list, roi_patterns, voxel_size);

%% b0 and fa

plotDonutFAMeansB0Meanplotted(project_directory, project_name, ...
    subject_list, roi_patterns, voxel_size);


%% plotting all 

plotAllADCValues(project_directory, project_name, subject_list,...
    roi_patterns, voxel_size);


%% plot radial
% 1)  get concentric ci

plotConcentricCircles(project_directory, project_name, subject_list,...
    roi_patterns, voxel_size);

