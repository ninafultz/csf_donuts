clear; clc; close all;

%% PARAMETERS
projPath = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\';
scriptsPath = 'R:\- Gorter\- Personal folders\Fultz, N\scripts\csfdonuts_lydiane\';
centralDataPath = 'R:\- Gorter\CSF_STREAM\Data\'; 
physioConditions = {'cardiac', 'resp','random'};
physioFolders = {'Cardiac', 'Respiration','Random'};
signals = {'ADC', 'FA'};

nPhasesDefault = 6;

roi_internal = {'aca_right_internaldonut','aca_left_internaldonut'};

addpath(genpath(scriptsPath));
addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\toolbox\'));

%% SUBJECTS
subjectDirs = dir(projPath);
subjectDirs = subjectDirs([subjectDirs.isdir]);
subjectDirs = subjectDirs(contains({subjectDirs.name}, 'Rec'));

%% ALL COMBINATIONS
[subject_idx, physio_idx, roi_idx, signal_idx] = ndgrid(1:numel(subjectDirs), ...
    1:numel(physioConditions), 1:numel(roi_internal), 1:numel(signals));
combos = [subject_idx(:), physio_idx(:), roi_idx(:), signal_idx(:)];

%logging cause some scans are randomly just cut?
errorLog = struct('index',{}, 'subject',{}, 'physio',{}, ...
                  'roi',{}, 'signal',{}, 'message',{}, 'identifier',{}, 'stack',{});


%% MAIN LOOP
for c = 1:size(combos,1)
    close all;
    s = combos(c,1);
    p = combos(c,2);
    r = combos(c,3);
    t = combos(c,4);

    subject_code = subjectDirs(s).name;
    physio = physioConditions{p};
    physiofolder = physioFolders{p};
    roiName = roi_internal{r};
    signal = signals{t};

    fprintf('\n--- Processing %s | %s | %s | %s ---\n', subject_code, physio, roiName, signal);
 try
            %% PATHS
            physio_bin = fullfile(projPath, subject_code, 'physio_binning');
            physio_dir = fullfile(projPath, subject_code, physiofolder, 'T2prep','Results');
            sourceDir  = fullfile(centralDataPath, subject_code, physiofolder, 'T2prep','Results');
            outputDir  = fullfile(scriptsPath, 'plots', 'nov112025');
          
            %% SKIP CHECK
            saveFile = fullfile(physio_bin, sprintf('%s_%s_%s_%s_physio_phase_thr50.mat', ...
                subject_code, roiName, physio, signal));
         
            voxelwisePlotFile = fullfile(outputDir, sprintf('%s_%s_%s_%s_voxelwise.png', ...
                subject_code, roiName, physio, signal));
        
            if exist(saveFile,'file') && exist(voxelwisePlotFile,'file')
                fprintf('Skipping (outputs already exist)\n');
                continue;
            end
        
            %% COPY SOURCE FILES IF NEEDED
            if ~exist(physio_dir,'dir'); mkdir(physio_dir); end
            sourceFiles = dir(fullfile(sourceDir,'DTIresult_phase*.mat'));
            if isempty(sourceFiles)
                % fallback path
                sourceDir = fullfile(centralDataPath, subject_code, physiofolder, 'Results');
                sourceFiles = dir(fullfile(sourceDir,'DTIresult_phase*.mat'));
            end
            targetFiles = dir(fullfile(physio_dir,'DTIresult_phase*.mat'));
            targetNames = {targetFiles.name};
            for k = 1:numel(sourceFiles)
                if ~ismember(sourceFiles(k).name, targetNames)
                    fprintf('Copying %s...\n', sourceFiles(k).name);
                    copyfile(fullfile(sourceDir,sourceFiles(k).name), ...
                        fullfile(physio_dir,sourceFiles(k).name));
                end
            end
        
            %% ROI LOADING

            if strcmp(subject_code, '20191029_Rec')
                roi_pvsas_file = find_roi_file(fullfile(projPath, subject_code, 'ROIs_neworientation', ...
                    roi_internal{r}));
            else
                roi_pvsas_file = find_roi_file(fullfile(projPath, subject_code, 'ROIs', ...
                    roi_internal{r}));
            end

                roi_pvsas = niftiread(roi_pvsas_file) > 0;
              
            %% CHECK NIFTIS / CONVERSION
            expected_files = arrayfun(@(i) sprintf('%s_DTIresult_phase%d_%s_thr50.nii', physio, ...
                i, signal), 1:nPhasesDefault, 'UniformOutput', false);
            file_exists = cellfun(@(f) exist(fullfile(physio_bin,f),'file')==2, ...
                expected_files);
            if ~all(file_exists)
                fprintf('Running DTIphases_to_niftis for %s %s %s...\n', subject_code, ...
                    physio, roiName);
                DTIphases_to_niftis(projPath, subject_code, physio_dir, physio);
            end
        
            %% LOAD PHASES
            nii_files = dir(fullfile(physio_bin, sprintf('%s_DTIresult_phase*_%s_thr50.nii*', ...
                physio, signal)));
            nPhases = numel(nii_files);
            if nPhases ~= nPhasesDefault
                warning('Skipping %s %s: found %d phases (expected %d)', subject_code, ...
                    physio, nPhases, nPhasesDefault);
                continue;
            end
        

             load_phases = @(dirpath, physio, signal) arrayfun(@(i) struct( ...
                'data', niftiread(fullfile(dirpath, sprintf('%s_DTIresult_phase%d_%s_thr50.nii', ...
                physio, i, signal))), ...
                'info', niftiinfo(fullfile(dirpath, sprintf('%s_DTIresult_phase%d_%s_thr50.nii', ...
                physio, i, signal)))), ...
                1:nPhases, 'UniformOutput', false);
            phasesLoaded = load_phases(physio_bin, physio, signal);

            %% QUICK DIM CHECK
            nii_file = fullfile(physio_bin, sprintf('%s_DTIresult_phase1_ADC_thr50.nii', physio));
            nii_data_double = double(niftiread(nii_file));
            if ~isequal(size(nii_data_double), size(roi_pvsas))
                warning('ROI and DTI phase nifti size mismatch for %s - %s', subject_code, roiName);
                continue;
            end

            %% OPTIONAL VISUALIZATION FOR RESP
            % if strcmp(physio,'resp')
            %     nii_data = double(phasesLoaded{1,2}.data);
            %      nii_data = double(niftiread(nii_file));
            %     nii_data = mat2gray(min(max(nii_data,0),0.05)/0.05);
            %     rgb_vol = repmat(nii_data,[1 1 1 3]);
            %     rgb_vol(:,:,:,1) = rgb_vol(:,:,:,1) + 0.5*double(roi_pvsas);
            %     rgb_vol(:,:,:,2) = rgb_vol(:,:,:,2) + 0.5*double(roi_sas);
            %     rgb_vol(rgb_vol > 1) = 1;
            %     figure('Name', sprintf('%s - %s - ROI %s', subject_code, physio, roiName));
            %     imshow3Dfull(rgb_vol);
            %     title(sprintf('%s - %s - ROI %s (0-0.05 window)', subject_code, physio, roiName));
            % end
            % 
            %% RUN MAIN ANALYSIS FUNCTION
            plottingADCandFAacrossPhasesAllSubjectsACA(physio, signal, physio_bin, ...
                roi_pvsas, nPhases, phasesLoaded, roiName, subject_code);
     catch ME
                warning('Failure for combo %d (%s|%s|%s|%s): %s', c, ...
                    subject_code, physio, roiName, signal, ME.message);

                errorLog(end+1).index      = c;
                errorLog(end).subject      = subject_code;
                errorLog(end).physio       = physio;
                errorLog(end).roi          = roiName;
                errorLog(end).signal       = signal;
                errorLog(end).message      = ME.message;
                errorLog(end).identifier   = ME.identifier;
                errorLog(end).stack        = ME.stack;
     continue;
    end
end

