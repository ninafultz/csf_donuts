clear; clc; close all;

%% Parameters
projPath = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\';
centralDataPath = 'R:\- Gorter\CSF_STREAM\Data\'; 
physioConditions = {'cardiac','resp','random'};
physioFolders = {'Cardiac','Respiration','Random'};
signals = {'ADC', 'FA'}; % FA
nPhasesDefault = 6;

% ROI definitions
roi_internal = {'m1_right_internaldonut','m1_left_internaldonut', ...
    'm2_right_internaldonut','m2_left_internaldonut'};
roi_external = {'m1_right_externaldonut','m1_left_externaldonut', ...
    'm2_right_externaldonut','m2_left_externaldonut'};

% Add scripts path
addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\csfdonuts_lydiane'));
addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\toolbox\'));


%% Get all subjects
subjectDirs = dir(projPath);
subjectDirs = subjectDirs([subjectDirs.isdir]);
subjectDirs = subjectDirs(contains({subjectDirs.name}, '20201019_Reconstruction'));

%% Loop over subjects
for s = 1:numel(subjectDirs)
    error_messages = {};
   try 
    close all;
    subject_code = subjectDirs(s).name;
    subject_code = subjectDirs{s};
    fprintf('Processing subject: %s\n', subject_code);
    
    for p = 1:numel(physioConditions)
        physio = physioConditions{p};
        physiofolder = physioFolders{p};
        physio_bin = fullfile(projPath, subject_code, 'physio_binning');
        physio_dir = fullfile(projPath, subject_code, physiofolder, 'T2prep','Results');
        sourceDir = fullfile(centralDataPath, subject_code, physiofolder, 'T2prep', 'Results');

        
        % Make target Results folder if it doesn't exist
        if ~exist(physio_dir,'dir')
            mkdir(physio_dir);  % automatically creates intermediate folders
        end
        
        % List all DTIresult_phase*.mat files in the source
        sourceFiles = dir(fullfile(sourceDir, 'DTIresult_phase*.mat'));
        
        % List all DTIresult_phase*.mat files in the target
        targetFiles = dir(fullfile(physio_dir, 'DTIresult_phase*.mat'));
        targetNames = {targetFiles.name};
        
        % Copy only files that are missing
        for k = 1:numel(sourceFiles)
            if ~ismember(sourceFiles(k).name, targetNames)
                fprintf('Copying %s to target folder...\n', sourceFiles(k).name);
                copyfile(fullfile(sourceDir, sourceFiles(k).name), fullfile(physio_dir, sourceFiles(k).name));
            end
        end

        % if not in primary folder, then copy from other path
        if isempty(sourceFiles)
            warning('No DTIresult_phase*.mat files found for %s ..looking in Results folder', subject_code);
            sourceDir = fullfile(centralDataPath, subject_code, physiofolder, 'Results');
            sourceFiles = dir(fullfile(sourceDir, 'DTIresult_phase*.mat'));
            
            for k = 1:numel(sourceFiles)
                if ~ismember(sourceFiles(k).name, targetNames)
                    fprintf('Copying %s to target folder from fallback Results folder...\n', sourceFiles(k).name);
                    copyfile(fullfile(sourceDir, sourceFiles(k).name), ...
                             fullfile(physio_dir, sourceFiles(k).name));
                end
            end
        end

        for r = 1:numel(roi_internal)
            % Find ROI files (.nii or .nii.gz)
            roi_pvsas_file = find_roi_file(fullfile(projPath, subject_code, ...
                'ROIs', roi_internal{r}));
            roi_sas_file   = find_roi_file(fullfile(projPath, subject_code, ...
                'ROIs', roi_external{r}));

            % Load ROIs
            roi_pvsas = niftiread(roi_pvsas_file) > 0;
            roi_sas   = niftiread(roi_sas_file) > 0;

        for t = 1:numel(signals)
            % Check if conversion to niftis is needed
            expected_files = arrayfun(@(i) sprintf('%s_DTIresult_phase%d_%s.nii', physio, i, signals{t}), ...
                                      1:6, 'UniformOutput', false);
            file_exists = cellfun(@(f) exist(fullfile(physio_bin,f),'file')==2, expected_files);
            
            if ~all(file_exists)
                fprintf('Running DTIphases_to_niftis for %s %s %s...\n', subject_code, physio, roi_internal{r});
                DTIphases_to_niftis(projPath, subject_code, physio_dir, physio);
            end

            % Determine number of phases by counting files
            nii_files = dir(fullfile(physio_bin, sprintf('%s_DTIresult_phase*_%s.nii*', physio, signals{t})));
            nPhases = numel(nii_files);

            % Skip if no files or if number of phases is not 6
            if nPhases == 0 || nPhases ~= 6
                warning('Skipping %s %s: found %d DTI NIfTI files (expected 6).', subject_code, physio, nPhases);
                continue
            end

            % Load phases
            load_phases = @(dirpath, physio, signal) arrayfun(@(i) struct( ...
                'data', niftiread(fullfile(dirpath, sprintf('%s_DTIresult_phase%d_%s.nii', physio, i, signals{t}))), ...
                'info', niftiinfo(fullfile(dirpath, sprintf('%s_DTIresult_phase%d_%s.nii', physio, i, signals{t})))), ...
                1:nPhases, 'UniformOutput', false);
        
         
                phasesLoaded = load_phases(physio_bin, physio, signals{t});
                
                nii_file = fullfile(physio_bin, sprintf('%s_DTIresult_phase1_ADC.nii', physio));
                nii_data_double = double(niftiread(nii_file));
                roi_double = double(roi_pvsas);

                if isequal(size(nii_data_double), size(roi_double))
                    fprintf('dti phase nifti = roi size, yay!\n');
                else
                    error_messages{end+1} = sprintf('dti phase nifti not equal to roi size - sad. nii_data: [%s], roi_pvsas: [%s]', ...
                                             num2str(size(nii_data)), num2str(size(roi_pvsas)));
                end
                          if strcmp(physio, 'resp')
                              fprintf('Plotting roi on cardiac as test: %s\n', subject_code);
                               nii_file = fullfile(physio_bin, sprintf('%s_DTIresult_phase1_ADC.nii', physio));
                            if exist(nii_file,'file')
                                nii_data = double(niftiread(nii_file));
                                nii_data = mat2gray(nii_data);  % normalize to [0 1]
                                                    
                                % just visualizing things...
                                nii_data(nii_data < 0) = 0;           % clip below 0
                                nii_data(nii_data > 0.05) = 0.05;    % clip above 0.05
                                nii_data = nii_data / 0.05;          % normalize to [0,1] for display
                            
                                % Create RGB overlay
                                rgb_vol = repmat(nii_data, [1 1 1 3]);  % grayscale base
                                rgb_vol(:,:,:,1) = rgb_vol(:,:,:,1) + 0.5*double(roi_pvsas);  % red
                                rgb_vol(:,:,:,2) = rgb_vol(:,:,:,2) + 0.5*double(roi_sas);    % green
                                rgb_vol(rgb_vol > 1) = 1;  % clip
                            
                                % plot..
                                figure('Name', sprintf('%s - %s - ROI %s', subject_code, physio, roi_internal{r}));
                                imshow3Dfull(rgb_vol);
                                title(sprintf('%s - %s - ROI %s (0-0.05 window)', subject_code, physio, roi_internal{r}));                            else

                            end
                          end

                        plottingADCandFAacrossPhasesAllSubjects(physio, signals{t}, ...
                        physio_bin, roi_pvsas, roi_sas, nPhases, phasesLoaded, ...
                        roi_internal{r}, subject_code);
              end
        end
    end
     catch 
         error_messages{end+1} = sprintf('Skipping %s %s: %d .... there is an issue.', subject_code, physio)
        continue;
    end
end


%% errors

% After all checks, display errors if any
if ~isempty(error_messages)
    fprintf('The following issues were found:\n');
    for i = 1:length(error_messages)
        fprintf('%s\n', error_messages{i});
    end
end