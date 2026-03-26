%% plotting Concentric Circles lydianes way
% csf donut protocol for CAA patients
% nina fultz january 2026
% n.e.fultz@lumc.nl
%% goals:
clear
clc
%%
% defining paths
project_directory = 'R:\- Gorter\- Personal folders\Fultz, N\';
project_name      = 'csfdonuts_lydiane';
scripts           = fullfile(project_directory, 'scripts', project_name);
%%params
voxSize    = 0.45;
maxDist    = 10;
binWidth   = 0.45;
addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts)));

CCDir          = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\concentricCircleResults';
ROIs           = {'M2'};
dilationDiameter = 1:10;
binCenters     = (0:length(dilationDiameter(:))-1) * voxSize;

% ── colours ──────────────────────────────────────────────────────────────
colLeftInd  = [0.20 0.40 1.00];   % blue  – left individual traces
colRightInd = [0.00 0.70 0.45];   % green – right individual traces
colLeftMean = [0.00 0.20 0.85];   % dark blue  – left mean
colRightMean= [0.00 0.50 0.20];   % dark green – right mean
colOverall  = [0.10 0.10 0.10];   % near-black – overall mean

colLeftIndB0  = [1.00 0.40 0.20]; % orange – left B0 individual
colRightIndB0 = [0.85 0.10 0.50]; % pink   – right B0 individual
colLeftMeanB0 = [0.80 0.20 0.00]; % dark orange – left B0 mean
colRightMeanB0= [0.60 0.00 0.35]; % dark pink   – right B0 mean
colOverallB0  = [0.40 0.00 0.00]; % dark red     – overall B0 mean

for r = 1:numel(ROIs)
    ROI = ROIs{r};
    cd(CCDir);

    tmp = load(['allCSFmobilityLydiane' ROI '_Median_left.mat']);
    ADC_left  = tmp.averageADC_MCA;

    tmp = load(['allCSFmobilityLydiane' ROI '_Median_right.mat']);
    ADC_right = tmp.averageADC_MCA;

    tmp = load(['allB0Lydiane' ROI '_Median_left.mat']);
    B0_left   = tmp.averageCSF_MCA;

    tmp = load(['allB0Lydiane' ROI '_Median_right.mat']);
    B0_right  = tmp.averageCSF_MCA;

    nSubjects = size(ADC_left, 1);
    subjectCols = lines(nSubjects);

    % ── means ─────────────────────────────────────────────────────────────
    meanADC_L   = mean(ADC_left,  1);
    meanADC_R   = mean(ADC_right, 1);
    meanADC_all = mean([ADC_left; ADC_right], 1);

    meanB0_L    = mean(B0_left,  1);
    meanB0_R    = mean(B0_right, 1);
    meanB0_all  = mean([B0_left; B0_right], 1);

    %% ── Figure 1: CSF Mobility ───────────────────────────────────────────
    figure('Name', ['CSF Mobility — ' ROI], 'NumberTitle', 'off');
    set(gcf, 'Color', 'w', 'Renderer', 'painters');
    hold on;

    % individual traces — same color per subject, dotted=left, solid=right
    for i = 1:nSubjects
        col = subjectCols(i,:);
        plot(binCenters, ADC_left(i,:),  ':', 'LineWidth', 2, 'Color', [col 0.5]);
        plot(binCenters, ADC_right(i,:), '-', 'LineWidth', 2, 'Color', [col 0.5]);
    end

    % mean lines on top
    hL_mean   = plot(binCenters, meanADC_L,   ':',  'LineWidth', 2.5, 'Color', colLeftMean);
    hR_mean   = plot(binCenters, meanADC_R,   '-',  'LineWidth', 2.5, 'Color', colRightMean);
    hAll_mean = plot(binCenters, meanADC_all, '-',  'LineWidth', 2.5, 'Color', colOverall);

    ylabel(['CSF-mobility: ' ROI]);
    xlabel('Distance from vessel (mm)');
    title(['CSF Mobility — ' ROI]);
    xlim([0 3]);

    % Legend: subject colors + line style key
    hSubj = arrayfun(@(i) plot(nan, nan, '-', 'Color', subjectCols(i,:), ...
        'LineWidth', 1.5), 1:nSubjects, 'UniformOutput', true);
    hLstyle  = plot(nan, nan, 'k:', 'LineWidth', 1.5);
    hRstyle  = plot(nan, nan, 'k-', 'LineWidth', 1.5);
    hMeanL   = plot(nan, nan, ':', 'LineWidth', 2.5, 'Color', colLeftMean);
    hMeanR   = plot(nan, nan, '-', 'LineWidth', 2.5, 'Color', colRightMean);
    hMeanAll = plot(nan, nan, '-', 'LineWidth', 2.5, 'Color', colOverall);

    subjLabels = cellfun(@(s) s(1:8), subject_list, 'UniformOutput', false);
    allHandles = [hSubj(:)', hLstyle, hRstyle, hMeanL, hMeanR, hMeanAll];
    allLabels  = [subjLabels(:)', {'Left (indiv.)', 'Right (indiv.)', ...
                  'Mean left', 'Mean right', 'Mean overall'}];
    legend(allHandles, allLabels, 'Location', 'eastoutside', 'FontSize', 7);

    %% ── Figure 2: CSF Signal (B0) ────────────────────────────────────────
    % figure('Name', ['CSF Signal — ' ROI], 'NumberTitle', 'off');
    % set(gcf, 'Color', 'w', 'Renderer', 'painters');
    % hold on;
    % 
    % for i = 1:nSubjects
    %     col = subjectCols(i,:);
    %     plot(binCenters, B0_left(i,:),  ':', 'LineWidth', 1.2, 'Color', [col 0.5]);
    %     plot(binCenters, B0_right(i,:), '-', 'LineWidth', 1.2, 'Color', [col 0.5]);
    % end
    % 
    % hL_B0mean   = plot(binCenters, meanB0_L,   ':',  'LineWidth', 2.5, 'Color', colLeftMeanB0);
    % hR_B0mean   = plot(binCenters, meanB0_R,   '-',  'LineWidth', 2.5, 'Color', colRightMeanB0);
    % hAll_B0mean = plot(binCenters, meanB0_all, '-',  'LineWidth', 2.5, 'Color', colOverallB0);
    % 
    % ylabel(['CSF Signal: ' ROI]);
    % xlabel('Distance from vessel (mm)');
    % title(['CSF Signal — ' ROI]);
    % xlim([0 3]);
    % 
    % hSubj2 = arrayfun(@(i) plot(nan, nan, '-', 'Color', subjectCols(i,:), ...
    %     'LineWidth', 1.5), 1:nSubjects, 'UniformOutput', true);
    % hLstyle2  = plot(nan, nan, 'k:', 'LineWidth', 1.5);
    % hRstyle2  = plot(nan, nan, 'k-', 'LineWidth', 1.5);
    % hMeanL2   = plot(nan, nan, ':', 'LineWidth', 2.5, 'Color', colLeftMeanB0);
    % hMeanR2   = plot(nan, nan, '-', 'LineWidth', 2.5, 'Color', colRightMeanB0);
    % hMeanAll2 = plot(nan, nan, '-', 'LineWidth', 2.5, 'Color', colOverallB0);
    % 
    % allHandles2 = [hSubj2(:)', hLstyle2, hRstyle2, hMeanL2, hMeanR2, hMeanAll2];
    % allLabels2  = [subjLabels(:)', {'Left (indiv.)', 'Right (indiv.)', ...
    %                'Mean left', 'Mean right', 'Mean overall'}];
    % legend(allHandles2, allLabels2, 'Location', 'eastoutside', 'FontSize', 7);

end