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

    % ── load left / right ────────────────────────────────────────────────
    tmp = load(['allCSFmobilityLydiane' ROI '_Median_left.mat']);
    ADC_left  = tmp.averageADC_MCA;          % nSubjects x nBins

    tmp = load(['allCSFmobilityLydiane' ROI '_Median_right.mat']);
    ADC_right = tmp.averageADC_MCA;

    tmp = load(['allB0Lydiane' ROI '_Median_left.mat']);
    B0_left   = tmp.averageCSF_MCA;

    tmp = load(['allB0Lydiane' ROI '_Median_right.mat']);
    B0_right  = tmp.averageCSF_MCA;

    normADC_L = ADC_left;
    normADC_R = ADC_right;
    normB0_L  = B0_left;
    normB0_R  = B0_right;

    % ── means ─────────────────────────────────────────────────────────────
    meanADC_L   = mean(normADC_L, 1);
    meanADC_R   = mean(normADC_R, 1);
    meanADC_all = mean([normADC_L; normADC_R], 1);

    meanB0_L    = mean(normB0_L,  1);
    meanB0_R    = mean(normB0_R,  1);
    meanB0_all  = mean([normB0_L; normB0_R], 1);

 % ── per-subject subplots ──────────────────────────────────────────────
    rangeMask = binCenters <= 3;
    nSubjects = size(normADC_L, 1);
    nCols     = ceil(sqrt(nSubjects));
    nRows     = ceil(nSubjects / nCols);

    figure('Name', ['ADC per subject — ' ROI], 'NumberTitle', 'off');
    set(gcf, 'Color', 'w', 'Renderer', 'painters');

    for s = 1:nSubjects
        subplot(nRows, nCols, s);
        hold on;

        % ── left & right traces ──────────────────────────────────────
        plot(binCenters, normADC_L(s,:), '-', ...
             'Color', colLeftMean,  'LineWidth', 1.8);
        plot(binCenters, normADC_R(s,:), '-', ...
             'Color', colRightMean, 'LineWidth', 1.8);

        % ── max peak in 0–1.5 mm per side ────────────────────────────
        peakL     = max(normADC_L(s, rangeMask));
        peakR     = max(normADC_R(s, rangeMask));
        threshL   = peakL * 0.80;
        threshR   = peakR * 0.80;
        ylim([0  max(peakL, peakR) + 0.01]); 

        yline(threshL, '--', 'LineWidth', 1.4, 'Color', colLeftMean);
        yline(threshR, '--', 'LineWidth', 1.4, 'Color', colRightMean);

        % ── cosmetics ────────────────────────────────────────────────
        xlim([0 3]);
        title(['Subject ' num2str(s)], 'FontSize', 9);
        xlabel('Distance (mm)', 'FontSize', 8);
        ylabel('ADC',           'FontSize', 8);

        if s == 1
            legend('Left', 'Right', '−20% left peak', '−20% right peak', ...
                   'Location', 'northeast', 'FontSize', 7);
        end

        hold off;
    end

    sgtitle(['ADC profiles — ' ROI], 'FontWeight', 'bold');

    % ── percentage of vessels that hit the –20 % threshold ───────────────
    % A vessel counts if its ADC profile dips back to <= 80 % of its
    % 0–3 mm peak at ANY bin after the peak location.

    rangeMaskFull = true(1, size(normADC_L, 2));   % full distance range
    hitCount = 0;
    totalVessels = 0;

    sides   = {normADC_L, normADC_R};
    sideNames = {'Left', 'Right'};

    for sideIdx = 1:2
        data = sides{sideIdx};
        for s = 1:nSubjects
            profile   = data(s, :);
            peak      = max(profile(rangeMask));        % peak in 0–3 mm
            threshold = peak * 0.80;

            % find bin of peak
            [~, peakBin] = max(profile .* rangeMask);  % first max in range

            % check if profile drops to <= threshold AFTER the peak
            postPeak = profile(peakBin:end);
            doesDip  = any(postPeak <= threshold);

            hitCount     = hitCount + doesDip;
            totalVessels = totalVessels + 1;

            fprintf('Subject %2d | %5s | peak = %.4f | thresh = %.4f | hit = %d\n', ...
                    s, sideNames{sideIdx}, peak, threshold, doesDip);
        end
    end

    pctHit = 100 * hitCount / totalVessels;
    fprintf('\n=== ROI: %s ===\n', ROI);
    fprintf('Vessels hitting –20%% threshold: %d / %d  (%.1f%%)\n\n', ...
            hitCount, totalVessels, pctHit);
end