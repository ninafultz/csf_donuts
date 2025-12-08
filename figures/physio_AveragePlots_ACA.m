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
physioConditions = {'resp'};
physioFolders = {'Respiration'};
signals = {'ADC', 'FA'};

nPhasesDefault = 6;


roi_internal = {'aca_right_internaldonut','aca_left_internaldonut'};

roiPairs = {{'aca_right_internaldonut','aca_right_externaldonut'}};

addpath(genpath(scriptsPath));
addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\toolbox\'));


adcSignals = {'ADC'}; 
faSignals  = {'FA'};  
signalGroups = {adcSignals, faSignals};
groupTitles  = {'CSF-mobility', 'FA'};
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

        

        ts_normalizedAll = mean(ts_normalized, 1, 'omitnan');
%       
        
        maxValue = max(ts(:));
        minValue = min(ts(:));

        figure;
        sgtitle([subjectCode ' ' roi ' ' physio ' ' signal]);
        subplot(1,3,1)
        plot(1:size(ts, 2), ts, '-');
        subtitle('original ts')
        ylim([minValue maxValue]);

        maxValue = max(aligned_ts(:));
        minValue = min(aligned_ts(:));

        subplot(1,3,2)
        plot(1:size(aligned_ts, 2), aligned_ts, '-')
        subtitle('realigned and cut ts')
        ylim([minValue maxValue]);

        subplot(1,3,3)
        plot(1:size(aligned_ts, 2), ts_normalized, '-', 'Color', [0 0 1 0.2]); hold on
        plot(1:size(aligned_ts, 2), ts_normalizedAll, '-', 'Color', [0 0 1]);
        maxValue = max(ts_normalized(:));
        minValue = min(ts_normalized(:));
        subtitle('normalized')
        ylim([minValue maxValue]);

    % Add row to table
    newRow = {subjectCode, roi, physio, signal, ts_normalizedAll};
    allAligned = [allAligned; newRow];
%
end

%% getting mean for each ROI 

for s = 1:length(signals)
    sigName = signals{s};
    
    for p = 1:length(physioConditions)
        physioName = physioConditions{p};
         
        for r = 1:length(roiPairs)
            internalROI = roiPairs{r}{1};
            
            % Filter table
            idxInternal = allAligned.roi == internalROI & allAligned.physio == physioName & allAligned.signal == sigName;
            
            if ~any(idxInternal) 
                fprintf('No data for %s', internalROI);
            end
                      
            tsInternalCell = allAligned.ts(idxInternal);
            tsInternal = vertcat(tsInternalCell{:});  % size: totalCycles x 6

            meanInternal = mean(tsInternal,1);
            
        end
        
        xlabel('Phase');
        ylabel('Normalized TS');
        legend('Location','best');
        grid on;
    end
end

%% plotting ROIs - right vs. left, FA and ADC


for g = 1:1
    figure('Name', groupTitles{g});
    sgtitle(groupTitles{g});
    
    signalsToPlot = signalGroups{g};
    
    for p = 1:length(physioConditions)
        physioName = physioConditions{p};
        
        for r = 1:length(roiPairs)
            internalROI = roiPairs{r}{1};
            
            subplot(length(physioConditions), length(roiPairs), (p-1)*length(roiPairs) + r); hold on;
            titleStr = sprintf('%s - %s', physioName, internalROI);
            title(titleStr);
            
            for s = 1:length(signalsToPlot)
                sigName = signalsToPlot{s};
                
                % Filter table for physio condition
                idxInternal = allAligned.roi == internalROI & allAligned.physio == physioName & allAligned.signal == sigName;
                
                if ~any(idxInternal)
                    warning('No data for %s or %s', internalROI);
                    continue;
                end
                
                tsInternal = vertcat(allAligned.ts{idxInternal});
                
                meanInternal = mean(tsInternal,1); meanInternal = meanInternal(:)';
                
                phases = (1:nPhasesDefault-1);

                
                % Plot mean as filled dots only
                p1 = plot(phases, meanInternal, '-o', 'MarkerFaceColor', [0 0 1], 'MarkerEdgeColor', [0 0 1], 'MarkerSize', 5);

                % Plot individual trials (semi-transparent lines)
                plot(phases, tsInternal', '-', 'Color', [0 0 1 0.2]);
                legend([p1], {'PVSAS'}, 'Location','best');
            end
            
            xlabel('Phase'); ylabel('% Signal Change');
           % ylim([0.95 1.05]);
            
        end
    end
end

%% all cardiac, resp, random in one plot

colors = lines(length(physioConditions));   % auto distinct colors

for g = 1:2
    figure('Name', groupTitles{g}); 
    sgtitle(groupTitles{g});
    
    signalsToPlot = signalGroups{g};
    
    for r = 1:length(roiPairs)
        internalROI = roiPairs{r}{1};
        
        subplot(1, length(roiPairs), r); hold on;
        title(sprintf('%s vs %s', internalROI));
        
            for p = 1:length(physioConditions)
                physioName = physioConditions{p};
            
                for s = 1:length(signalsToPlot)
                    sigName = signalsToPlot{s};
            
                    % Filter table
                    idxInternal = allAligned.roi == internalROI & ...
                                  allAligned.physio == physioName & ...
                                  allAligned.signal == sigName;
            
                  
                    if ~any(idxInternal)
                        continue;
                    end
            
                    tsInternal = vertcat(allAligned.ts{idxInternal});
            
                    meanInternal = mean(tsInternal,1);
            
                    nInternal = size(tsInternal,1);
            
                    ciInternal = 1.96 * std(tsInternal) / sqrt(nInternal);
            
                    phases = (1:nPhasesDefault-1);

                    % Plot shaded CIs
                    fill([phases fliplr(phases)], [meanInternal+ciInternal fliplr(meanInternal-ciInternal)], ...
                        colors(p,:), 'FaceAlpha', 0.2, 'EdgeColor','none');
               
                    % Plot internal/external means
                    plot(phases, meanInternal, '-o', 'Color', colors(p,:), 'MarkerFaceColor', colors(p,:));
                    plot(phases, tsInternal, '-', 'Color', [colors(p,:) 0.3]);

                end
            end
        
            xlabel('Phase');
        ylabel('% Signal Change');
        
        legendEntries = {};
        for p = 1:length(physioConditions)
            legendEntries{end+1} = sprintf('%s – internal', physioConditions{p});
        end
        
        legend(legendEntries, 'Location','best');
    
    
    end
end


%%


for g = 1:length(signals); %1:2
    figure('Name', groupTitles{g}, 'Renderer', 'painters');

    sgtitle(groupTitles{g});
    sigName = signals{g};

    for r = 1:length(roiPairs)
        internalROI = roiPairs{r}{1};
        externalROI = roiPairs{r}{2};
        
        subplot(1, 2, r); hold on;
        title(sprintf('%s vs %s', internalROI));
        
            for p = 1:length(physioConditions)
                physioName = physioConditions{p};
            
               % Example ROI pattern: m1_left_internaldonut or m2_right_internaldonut
                % Goal: match "m1_*_internaldonut" or "m2_*_internaldonut"
                
         
                % Extract the first component (e.g., 'm1' or 'm2') dynamically
                tokens = regexp(roiPairs{r}{1}, '^([a-z]+)_', 'tokens', 'once');
                baseROI = tokens{1};
                
                % Build a regex: base + anything in middle + final component
                internalPattern = [baseROI '.*internaldonut'];
                
                % Find matching rows
                idxInternal = ~cellfun('isempty', regexp(allAligned.roi, internalPattern)) & ...
                              allAligned.physio == physioName & ...
                              allAligned.signal == sigName;
                
            
                
                nInternal = sum(idxInternal);
                disp(nInternal)

                tsInternal = vertcat(allAligned.ts{idxInternal});
        
                meanInternal = mean(tsInternal,1);
        
                nInternal = size(tsInternal,1);
        
                    ciInternal = 1.96 * std(tsInternal) / sqrt(nInternal);

                   phases = (1:nPhasesDefault-1);
                % Compute SEM instead of 95% CI
                    errInternal = std(tsInternal) / sqrt(nInternal);
                    
                  
                    % Slightly translucent mean/internal/external lines
                   plot(phases, meanInternal, '-o', 'Color', 'magenta', 'MarkerFaceColor', 'magenta');
                  
                    fill([phases fliplr(phases)], [meanInternal+ciInternal fliplr(meanInternal-ciInternal)], ...
                        'magenta', 'FaceAlpha', 0.2, 'EdgeColor','none');


                    % plot(phases, tsInternal,   '-', 'Color', [colors(p,:) 0.2]);
                    % 
                    % plot(phases, tsExternal,   '-', 'Color', [colors(p,:) 0.2]);
                % ylim([-5 6]); % for cardiac 
               ylim([-2 2]); % for resp

                    % %  % Plot shaded SEM
                    % fill([phases fliplr(phases)], ...
                    %      [meanInternal + errInternal  fliplr(meanInternal - errInternal)], ...
                    %      colors(p,:), 'FaceAlpha', 0.3, 'EdgeColor','none');
                    % 
                    % fill([phases fliplr(phases)], ...
                    %      [meanExternal + errExternal  fliplr(meanExternal - errExternal)], ...
                    %      colors(p,:), 'FaceAlpha', 0.3, 'EdgeColor','none'); 
                    
              end
         end
        
        % Manual legend
        legend({'Cardiac PVSAS mean', 'Cardiac SAS mean', 'Random PVSAS mean', 'Random SAS mean',}, 'Location','best');

        xlabel('Phase');
        ylabel('% Signal Change');

    end



