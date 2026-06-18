%% plotting Concentric Circles lydianes way
% csf donut protocol
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

    % ── load left / right ────────────────────────────────────────────────
    tmp = load(['allCSFmobilityLydiane' ROI '_Median_left.mat']);
    ADC_left  = tmp.averageADC_MCA;

    tmp = load(['allCSFmobilityLydiane' ROI '_Median_right.mat']);
    ADC_right = tmp.averageADC_MCA;

    tmp = load(['allB0Lydiane' ROI '_Median_left.mat']);
    B0_left   = tmp.averageCSF_MCA;

    tmp = load(['allB0Lydiane' ROI '_Median_right.mat']);
    B0_right  = tmp.averageCSF_MCA;

    % ── normalise each subject by its own peak ───────────────────────────
    normADC_L = ADC_left  ./ max(ADC_left,  [], 2);
    normADC_R = ADC_right ./ max(ADC_right, [], 2);
    normB0_L  = B0_left   ./ max(B0_left,   [], 2);
    normB0_R  = B0_right  ./ max(B0_right,  [], 2);

    % ── means ────────────────────────────────────────────────────────────
    meanADC_L   = mean(normADC_L, 1);
    meanADC_R   = mean(normADC_R, 1);

    meanB0_L    = mean(normB0_L,  1);
    meanB0_R    = mean(normB0_R,  1);

    ADC_subj = (normADC_L + normADC_R)/2;   
    B0_subj  = (normB0_L  + normB0_R )/2;

    meanADC_all = mean(ADC_subj,1);
    meanB0_all  = mean(B0_subj,1);

    ciADC_all = 1.96 * std(ADC_subj,0,1) / sqrt(11);
    ciB0_all  = 1.96 * std(B0_subj,0,1)  / sqrt(11);


    % ── std ──────────────────────────────────────────────────────────────
    stdADC_L   = std(normADC_L,   0, 1);
    stdADC_R   = std(normADC_R,   0, 1);
    stdADC_all = std([normADC_L; normADC_R], 0, 1);

    stdB0_L    = std(normB0_L,    0, 1);
    stdB0_R    = std(normB0_R,    0, 1);
    stdB0_all  = std([normB0_L; normB0_R], 0, 1);

    % ── helper: shaded fill ───────────────────────────────────────────────
    % usage: shadedFill(binCenters, mean, std, color, alpha)
    shadeFill = @(x, m, s, col, alph) fill( ...
        [x, fliplr(x)], [m+s, fliplr(m-s)], col, ...
        'EdgeColor', 'none', 'FaceAlpha', alph);
    %% ── Figure 1: CSF Mobility ───────────────────────────────────────────
    figure('Name', ['CSF Mobility Normalized — ' ROI], 'NumberTitle', 'off');
    set(gcf, 'Color', 'w', 'Renderer', 'painters');
    hold on;

    % individual traces
    hL_ind = plot(binCenters, normADC_L', '-', 'LineWidth', 0.8, 'Color', [colLeftInd  0.20]);
    hR_ind = plot(binCenters, normADC_R', '-', 'LineWidth', 0.8, 'Color', [colRightInd 0.20]);

    % std shading — drawn before mean lines so lines sit on top
    % shadeFill(binCenters, meanADC_L,   stdADC_L,   colLeftMean,  0.20);
    % shadeFill(binCenters, meanADC_R,   stdADC_R,   colRightMean, 0.20);
    % shadeFill(binCenters, meanADC_all, stdADC_all, colOverall,   0.15);
    shadeFill(binCenters, meanADC_all, ciADC_all, colOverall, 0.15);

    % mean lines
    hL_mean   = plot(binCenters, meanADC_L,   '-',  'LineWidth', 2.0, 'Color', colLeftMean);
    hR_mean   = plot(binCenters, meanADC_R,   '--', 'LineWidth', 2.0, 'Color', colRightMean);
    hAll_mean = plot(binCenters, meanADC_all, 'k-', 'LineWidth', 2.5, 'Color', colOverall);

    ylabel(['CSF-mobility (norm. to peak): ' ROI]);
    xlabel('Distance from vessel (mm)');
    title(['CSF Mobility — Peak Normalized — ' ROI]);
    xlim([0 3]);
    ylim([0.3 1.1]);

    legend([hL_ind(1), hR_ind(1), hL_mean, hR_mean, hAll_mean], ...
           {'ADC left (indiv.)', 'ADC right (indiv.)', ...
            'ADC mean left',     'ADC mean right',     'ADC mean overall'}, ...
           'Location', 'best', 'FontSize', 8);

    %% ── Figure 2: CSF Signal (B0) ────────────────────────────────────────
    figure('Name', ['CSF Signal Normalized — ' ROI], 'NumberTitle', 'off');
    set(gcf, 'Color', 'w', 'Renderer', 'painters');
    hold on;

    % individual traces
    hL_B0ind = plot(binCenters, normB0_L', '-', 'LineWidth', 0.8, 'Color', [colLeftIndB0  0.20]);
    hR_B0ind = plot(binCenters, normB0_R', '-', 'LineWidth', 0.8, 'Color', [colRightIndB0 0.20]);

    % std shading
    % shadeFill(binCenters, meanB0_L,   stdB0_L,   colLeftMeanB0,  0.20);
    % shadeFill(binCenters, meanB0_R,   stdB0_R,   colRightMeanB0, 0.20);
    % shadeFill(binCenters, meanB0_all, stdB0_all, colOverallB0,   0.15);
    shadeFill(binCenters, meanB0_all, ciB0_all, colOverallB0, 0.15);

    % mean lines
    hL_B0mean   = plot(binCenters, meanB0_L,   '-',  'LineWidth', 2.0, 'Color', colLeftMeanB0);
    hR_B0mean   = plot(binCenters, meanB0_R,   '--', 'LineWidth', 2.0, 'Color', colRightMeanB0);
    hAll_B0mean = plot(binCenters, meanB0_all, '-',  'LineWidth', 2.5, 'Color', colOverallB0);

    ylabel(['Non-motion-sensitized (norm. to peak): ' ROI]);
    xlabel('Distance from vessel (mm)');
    title(['CSF Signal — Peak Normalized — ' ROI]);
    xlim([0 3]);
    ylim([0.3 1.1]);

    legend([hL_B0ind(1), hR_B0ind(1), hL_B0mean, hR_B0mean, hAll_B0mean], ...
           {'B0 left (indiv.)', 'B0 right (indiv.)', ...
            'B0 mean left',     'B0 mean right',     'B0 mean overall'}, ...
           'Location', 'best', 'FontSize', 8);
end