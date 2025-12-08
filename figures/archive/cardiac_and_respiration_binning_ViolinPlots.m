clear; clc; close all;

%% PARAMETERS
projPath = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\';
scriptsPath = 'R:\- Gorter\- Personal folders\Fultz, N\scripts\csfdonuts_lydiane\';
centralDataPath = 'R:\- Gorter\CSF_STREAM\Data\'; 
physioConditions = {'cardiac', 'random'};
physioFolders = {'Cardiac', 'Random'};
% physioConditions = {'resp','random'};
% physioFolders = {'Respiration','Random'};

physioConditions = {'cardiac'};
physioFolders = {'Cardiac'};
% physioConditions = {'resp'};
% physioFolders = {'Respiration'};
physioConditions = {'random'};
physioFolders = {'Random'};
signals = {'ADC', 'FA'};

nPhasesDefault = 6;
 
roi_internal = {'m1_right_internaldonut','m1_left_internaldonut', ...
                'm1_right_externaldonut','m1_left_externaldonut', ...
                'm2_right_internaldonut','m2_left_internaldonut', ...
                'm2_right_externaldonut','m2_left_externaldonut', ...
                };

roiPairs = { ...
    {'m1_right_internaldonut','m1_right_externaldonut'}, ...
    {'m1_left_internaldonut','m1_left_externaldonut'}, ...
    {'m2_right_internaldonut','m2_right_externaldonut'}, ...
    {'m2_left_internaldonut','m2_left_externaldonut'}};

addpath(genpath(scriptsPath));
addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\toolbox\'));

%% SUBJECTS
subjectDirs = dir(projPath);
subjectDirs = subjectDirs([subjectDirs.isdir]);
subjectDirs = subjectDirs(contains({subjectDirs.name}, 'Rec'));

%% ALL COMBINATIONS
[subject_idx, physio_idx, roi_idx, signal_idx] = ndgrid( ...
    1:numel(subjectDirs), 1:numel(physioConditions), ...
    1:numel(roi_internal), 1:numel(signals));
combos = [subject_idx(:), physio_idx(:), roi_idx(:), signal_idx(:)];

%% Logging
errorLog = struct('index',{}, 'subject',{}, 'physio',{}, ...
                  'roi',{}, 'signal',{}, 'message',{}, ...
                  'identifier',{}, 'stack',{});

%% PROCESS LOOP
% Preallocate empty table
allAligned = table('Size',[0 5], ...
                   'VariableTypes', {'string','string','string','string','cell'}, ...
                   'VariableNames', {'subjectCode','roi','physio','signal','ts'});

for c = 1:size(combos,1)

    subjIdx   = combos(c,1);
    physIdx   = combos(c,2);
    roiIdx    = combos(c,3);
    sigIdx    = combos(c,4);

    subjectDir  = subjectDirs(subjIdx).name;
    subjectCode = subjectDir;

    physio = physioConditions{physIdx};
    roi    = roi_internal{roiIdx};
    signal = signals{sigIdx};

        % Use internal equivalent for loading if ROI is external
        if contains(roi, 'external')
            roi_temp = strrep(roi, 'external', 'internal');
        else
            roi_temp = roi;
        end
        
    physio_bin = fullfile(projPath, subjectDir, 'physio_binning');
    loadFile = fullfile(physio_bin, ...
        sprintf('%s_%s_%s_%s_physio_phase_thr50.mat', subjectCode, roi_temp, physio, signal));

    if ~isfile(loadFile)
        warning('Missing file: %s', loadFile);
        continue;
    end

    S = load(loadFile);
    R = S.physio_phase.(roi_temp);

    if contains(roi, 'internal')
            fieldName = sprintf('pvsas_voxel_values_%s_%s', physio, signal);
            %fieldName = sprintf('norm_pvsas_%s_%s', physio, signal);
        elseif contains(roi, 'external')
            fieldName = sprintf('sas_voxel_values_%s_%s', physio, signal);
            %fieldName = sprintf('norm_sas_%s_%s', physio, signal);
        else
        warning('ROI name does not contain internal or external: %s', roi);
    end

    if ~isfield(R, fieldName)
        warning('Missing field: %s', fieldName);
        continue;
    end

        ts = R.(fieldName);
        % checking
        %  0.0322    0.0313    0.0318    0.0312    0.0319    0.0316
        % 0.0406    0.0392    0.0386    0.0400    0.0371    0.0386
        [rowMax, colIdx] = max(ts, [], 2);

        % Preallocate aligned matrix
        aligned_ts = zeros(size(ts));

        [~, maxIdx] = max(ts, [], 2);  % maxIdx is 19x1, indices of max per row
        % 
       
        aligned_ts = zeros(size(ts));  % preallocate
        for r = 1:size(ts,1)
            aligned_ts(r,:) = circshift(ts(r,:), -(maxIdx(r)-1));
        end

        aligned_ts = aligned_ts(:, 2:end); % cut off first 

        % percent change from mean 
        ts_mean = mean(aligned_ts,2); % mean for each row 


        % Normalize each row by its own mean
        ts_normalized = 100 * (aligned_ts - ts_mean) ./ ts_mean;
        %ts_normalizedAll = mean(ts_normalized,1); % mean for each column
        ts_normalized_masked = ts_normalized;
        % ts_normalized_masked(abs(ts_normalized_masked) > 50) = NaN;

    % Compute row-mean or any metric ignoring the masked values

        ts_normalizedAll = mean(ts_normalized, 1, 'omitnan');

    % Add row to table
    newRow = {subjectCode, roi, physio, signal, ts_normalizedAll};
    allAligned = [allAligned; newRow];
%
end



    %% violin plots 


    roiPairs = { ...
    {'m1_right_internaldonut','m1_right_externaldonut'}, ...
    {'m2_right_internaldonut','m2_right_externaldonut'}};

for g = 1:length(signals)
    figure;
    sigName = signals{g};

    for r = 1:length(roiPairs)
        internalROI = roiPairs{r}{1};
        externalROI = roiPairs{r}{2};

        subplot(1, length(roiPairs), r); hold on;
        title(sprintf('%s vs %s', internalROI, externalROI));

        for p = 1:length(physioConditions)
            physioName = physioConditions{p};

            % --- Match all internal/external ROIs for this base ROI ---
            tokens = regexp(internalROI, '^(m\d+)_', 'tokens', 'once');
            baseROI = tokens{1};

            internalPattern = [baseROI '.*internaldonut'];
            externalPattern = [baseROI '.*externaldonut'];

            idxInternal = ~cellfun('isempty', regexp(allAligned.roi, internalPattern)) & ...
                          allAligned.physio == physioName & ...
                          allAligned.signal == sigName;

            idxExternal = ~cellfun('isempty', regexp(allAligned.roi, externalPattern)) & ...
                          allAligned.physio == physioName & ...
                          allAligned.signal == sigName;

            % --- Collapse left/right per subject ---
            subjectCodes = unique(allAligned.subjectCode(idxInternal));
            tsInternalCollapsed = zeros(length(subjectCodes),1);
            tsExternalCollapsed = zeros(length(subjectCodes),1);

            for s = 1:length(subjectCodes)
                subj = subjectCodes{s};

                subjInternalIdx = idxInternal & strcmp(allAligned.subjectCode, subj);
                subjExternalIdx = idxExternal & strcmp(allAligned.subjectCode, subj);

                tsInternalCollapsed(s) = mean(sum(-vertcat(allAligned.ts{subjInternalIdx}) .* ...
                                                    (vertcat(allAligned.ts{subjInternalIdx}) < 0), 2));
                tsExternalCollapsed(s) = mean(sum(-vertcat(allAligned.ts{subjExternalIdx}) .* ...
                                                    (vertcat(allAligned.ts{subjExternalIdx}) < 0), 2));
            end

            % --- Violin plot ---
            combinedData = [tsInternalCollapsed; tsExternalCollapsed];
            groupLabels = categorical([repmat("Internal", length(tsInternalCollapsed), 1); ...
                                       repmat("External", length(tsExternalCollapsed), 1)]);
            violinplot(combinedData, groupLabels, 'ShowData', false);

            % Overlay paired lines per subject
            nSubjects = length(subjectCodes);
            for i = 1:nSubjects
                plot([1 2], [tsInternalCollapsed(i) tsExternalCollapsed(i)], ...
                     'Color',[0.5 0.5 0.5], 'LineWidth',0.7);
                plot(1, tsInternalCollapsed(i), 'ko', 'MarkerFaceColor','k', 'MarkerSize',4);
                plot(2, tsExternalCollapsed(i), 'ko', 'MarkerFaceColor','k', 'MarkerSize',4);
            end

            ylabel('Area below zero');
            xticks([1 2]); xticklabels({'Internal','External'});

            % --- Paired statistical test ---
            [h,p] = ttest(tsInternalCollapsed, tsExternalCollapsed);
            fprintf('%s | %s | %s: Paired t-test: h=%d, p=%.4f\n', ...
                    sigName, physioName, baseROI, h, p);
        end
        hold off;
    end
end
