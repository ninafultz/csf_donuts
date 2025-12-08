%% Define project paths
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name      = 'csfdonuts_lydiane';
scripts           = fullfile(project_directory, 'scripts');

addpath(genpath(fullfile(scripts, project_name)));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts, 'functions')));

%% Environment variables
env_vars = {
    'FREESURFER_HOME', '/share/software/neuroImaging/freesurfer/linux-centos8_x86_64-7.4.1', ...
    'SINGULARITY_HOME', '/share/software/container/singularity/3.9.6', ...
    'AFNI_HOME', '/share/software/neuroImaging/AFNI/21.3.07/gcc-8.3.1', ...
};

for i = 1:2:length(env_vars)
    setenv(env_vars{i}, env_vars{i+1});
    setenv('PATH', [getenv('PATH'), ':', env_vars{i+1}, '/bin']);
end

%% Subjects folder
% subjects_folder = fullfile(project_directory, project_name);
% subject_dirs = dir(subjects_folder);

projPath = [project_directory, project_name];
subjectDirs = dir(projPath);
subjectDirs = subjectDirs([subjectDirs.isdir]);
subject_dirs = subjectDirs(contains({subjectDirs.name}, '20191022_Reconstruction'));

%% Create thresholding folder
thresholding_dir = fullfile(project_directory, project_name, 'thresholding');
if ~exist(thresholding_dir, 'dir')
    mkdir(thresholding_dir);
end

%% Loop through subjects
for s = 1:length(subject_dirs)
    subject_code = subject_dirs(s).name;
    subjPath = fullfile(projPath, subject_code);
    disp(['Processing subject: ', subject_code]);
    
    % Convert ADC and FA maps to NIfTIs
    [ADC_map_avg, FA_map_avg] = ADCandFAmaps_to_niftis(subjPath);

    % Run thresholding/masking function
    adc_and_fa_masking_threshold(subjPath, subject_code, ADC_map_avg, FA_map_avg);
    
    % Copy all NIfTIs from reoriented folder to thresholding folder with subject prefix
    reoriented_dir = fullfile(subjPath, 'reoriented');
    nifti_files = dir(fullfile(reoriented_dir, '*200*.nii'));
    
    for f = 1:length(nifti_files)
        src_file = fullfile(reoriented_dir, nifti_files(f).name);
        dest_file = fullfile(thresholding_dir, [subject_code, '_', nifti_files(f).name]);
        copyfile(src_file, dest_file);
    end
end


