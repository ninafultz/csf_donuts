
clear; clc; close all;
%% params and dirs
projPath = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\';
subject_code = '20201014_Reconstruction';
physio = 'cardiac'; % resp, or random
physiofolder = 'Cardiac'; % Resp, or Random
signal = 'FA'; % or ADC

physio_dir = [projPath subject_code '\' physiofolder '\' 'T2prep\Results\'];

roi_pvsas_file = find_roi_file([projPath subject_code ...
    '\ROIs\m1_right_internaldonut']);
roi_sas_file   = find_roi_file([projPath subject_code ...
    '\ROIs\m1_right_externaldonut']);

physio_bin = [projPath subject_code '\physio_binning\'];

nPhases = 6; % how many bins do you have

addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\csfdonuts_lydiane'));

%% Load ROIs
roi_pvsas = niftiread(roi_pvsas_file) > 0;
roi_sas   = niftiread(roi_sas_file) > 0;


%% dti mat files to niftis, make sure to check that values are the same 

expected_files = arrayfun(@(i) sprintf('%s_DTIresult_phase%d_%s.nii', physio, i, signal), ...
                          1:nPhases, 'UniformOutput', false);

% Check which files exist
file_exists = cellfun(@(f) exist(fullfile(physio_bin, f), 'file') == 2, expected_files);

if all(file_exists)
    fprintf('All %d phase NIfTIs exist. Skipping DTIphases_to_niftis.\n', nPhases);
else
    fprintf('Some NIfTIs missing. Running DTIphases_to_niftis...\n');
    DTIphases_to_niftis(projPath, subject_code, physio_dir);
    % make sure to check -- origin needs to be the same as always. 
end

%% Function to plot signal across phases

load_phases = @(dirpath) arrayfun(@(i) struct( ...
    'data', niftiread(fullfile(dirpath, sprintf('%s_DTIresult_phase%d_%s.nii', physio, i, signal))), ...
    'info', niftiinfo(fullfile(dirpath, sprintf('%s_DTIresult_phase%d_%s.nii', physio, i, signal)))), ...
    1:nPhases, 'UniformOutput', false);

if ~exist('phasesLoaded', 'var')
    phasesLoaded = load_phases(physio_bin);
end


plottingADCandFAacrossPhases(physio, signal, physio_bin, roi_pvsas, ...
    roi_sas, nPhases, phasesLoaded);