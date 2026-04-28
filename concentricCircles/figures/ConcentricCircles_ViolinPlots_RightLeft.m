%% defining paths
project_directory = 'R:\- Gorter\- Personal folders\Fultz, N\';
project_name      = 'csfdonuts_lydiane';
scripts           = fullfile(project_directory, 'scripts', project_name);

%% params
binWidth = 0.45;
addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\Violinplot-Matlab-master'));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts)));

ROI = 'M2';

subject_list = {
    '20191112_Reconstruction'
    '20201008_Reconstruction'
    '20201016_Reconstruction'
    '20191029_Rec'
    '20201014_Reconstruction'
    '20191022_Reconstruction'
    '20201020_Reconstruction'
    '20201111_Reconstruction'
    '20191210_Reconstruction'
    '20201019_Reconstruction'
    '20201110_Reconstruction'};

nSubjects = numel(subject_list);

shellEdges  = [0, 1.5, 3];
shellLabels = {'0–1.5 mm', '1.5–3 mm'};
nShells     = numel(shellLabels);

subjPath = fullfile(project_directory, project_name);
CCDir    = fullfile(subjPath, 'concentricCircleResults');
addpath(genpath(CCDir));
cd(CCDir);

% ── Load left / right ─────────────────────────────────────────────────────
tmp = load(['allCSFmobilityLydiane' ROI '_Median_left.mat']);
allADC_L = tmp.averageADC_MCA;

tmp = load(['allCSFmobilityLydiane' ROI '_Median_right.mat']);
allADC_R = tmp.averageADC_MCA;

tmp = load(['allB0Lydiane' ROI '_Median_left.mat']);
allB0_L = tmp.averageCSF_MCA;

tmp = load(['allB0Lydiane' ROI '_Median_right.mat']);
allB0_R = tmp.averageCSF_MCA;

% ── Bin into shells ───────────────────────────────────────────────────────
nBins      = size(allADC_L, 2);
binCenters = ((1:nBins)-1) * binWidth;

AllMeanADC_L = zeros(nSubjects, nShells);
AllMeanADC_R = zeros(nSubjects, nShells);
AllMeanB0_L  = zeros(nSubjects, nShells);
AllMeanB0_R  = zeros(nSubjects, nShells);

for k = 1:nSubjects
    for s = 1:nShells
        inShell = binCenters > shellEdges(s) & binCenters <= shellEdges(s+1);
        if any(inShell)
            AllMeanADC_L(k,s) = mean(allADC_L(k, inShell));
            AllMeanADC_R(k,s) = mean(allADC_R(k, inShell));
            AllMeanB0_L(k,s)  = mean(allB0_L(k, inShell));
            AllMeanB0_R(k,s)  = mean(allB0_R(k, inShell));
        else
            AllMeanADC_L(k,s) = NaN;
            AllMeanADC_R(k,s) = NaN;
            AllMeanB0_L(k,s)  = NaN;
            AllMeanB0_R(k,s)  = NaN;
        end
    end
end

% ── Pool L+R into each violin: [nSubjects*2 x nShells] ───────────────────
% Rows 1:nSubjects = left, rows nSubjects+1:end = right
matADC = [AllMeanADC_L; AllMeanADC_R];   % (2*nSubjects) x nShells
matB0  = [AllMeanB0_L;  AllMeanB0_R];

% ── Average L and R per subject before plotting ───────────────────────────
AllMeanADC = (AllMeanADC_L + AllMeanADC_R) / 2;   % nSubjects x nShells
AllMeanB0  = (AllMeanB0_L  + AllMeanB0_R)  / 2;

% ── Colours ───────────────────────────────────────────────────────────────
colLeft  = [0.20 0.40 1.00];   % blue
colRight = [0.00 0.65 0.35];   % green
jitterAmount = 0.07;
rng(1);

% Pre-generate jitter for left and right separately, per shell
xJitter_L_ADC = zeros(nSubjects, nShells);
xJitter_R_ADC = zeros(nSubjects, nShells);
xJitter_L_B0  = zeros(nSubjects, nShells);
xJitter_R_B0  = zeros(nSubjects, nShells);
for s = 1:nShells
    xJitter_L_ADC(:,s) = s + (rand(nSubjects,1) - 0.5) * jitterAmount;
    xJitter_R_ADC(:,s) = s + (rand(nSubjects,1) - 0.5) * jitterAmount;
    xJitter_L_B0(:,s)  = s + (rand(nSubjects,1) - 0.5) * jitterAmount;
    xJitter_R_B0(:,s)  = s + (rand(nSubjects,1) - 0.5) * jitterAmount;
end

%% ── Figure 1: CSF Mobility (ADC) ─────────────────────────────────────────
figure('Name', ['CSF Mobility — ' ROI], 'NumberTitle', 'off');
set(gcf, 'Color', 'w', 'Renderer', 'Painters');
hold on;

violinplot(AllMeanADC, shellLabels, 'ShowData', false);

% Jitter
xJitter = zeros(nSubjects, nShells);
rng(1);
for s = 1:nShells
    xJitter(:,s) = s + (rand(nSubjects,1) - 0.5) * 0.07;
end

% Connecting lines
for i = 1:nSubjects
    plot(xJitter(i,:), AllMeanADC(i,:), '-', ...
        'Color', [0.5 0.5 0.5 0.5], 'LineWidth', 0.8);
end

% Dots
for i = 1:nSubjects
    for s = 1:nShells
        if ~isnan(AllMeanADC(i,s))
            plot(xJitter(i,s), AllMeanADC(i,s), 'ko', ...
                'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none', 'MarkerSize', 4);
        end
    end
end

set(gca, 'XTick', 1:nShells, 'XTickLabel', shellLabels, ...
    'FontSize', 12, 'Box', 'off', 'TickDir', 'out');
ylabel('CSF Mobility (mm²/s)');
xlabel('Distance from Vessel');
title(['CSF Mobility — ' ROI ' — L+R averaged per subject']);
xlim([0.5 nShells+0.5]);
ylim([0 0.03]);

% t-test on 11 averaged values
[~, p, ~, stats] = ttest(AllMeanADC(:,1), AllMeanADC(:,2));
fprintf('ADC shell1 vs shell2 (L+R averaged): t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);


pvsas_mean = mean(AllMeanADC(:,1));
sas_mean = mean(AllMeanADC(:,2));

%% ── Figure 2: B0 ─────────────────────────────────────────────────────────
figure('Name', ['CSF Signal (B0) — ' ROI], 'NumberTitle', 'off');
set(gcf, 'Color', 'w', 'Renderer', 'Painters');
hold on;

violinplot(AllMeanB0, shellLabels, 'ShowData', false);
ylim([100 500]);

xJitter_B0 = zeros(nSubjects, nShells);
rng(1);
for s = 1:nShells
    xJitter_B0(:,s) = s + (rand(nSubjects,1) - 0.5) * 0.07;
end

for i = 1:nSubjects
    plot(xJitter_B0(i,:), AllMeanB0(i,:), '-', ...
        'Color', [0.5 0.5 0.5 0.5], 'LineWidth', 0.8);
end

for i = 1:nSubjects
    for s = 1:nShells
        if ~isnan(AllMeanB0(i,s))
            plot(xJitter_B0(i,s), AllMeanB0(i,s), 'ko', ...
                'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none', 'MarkerSize', 4);
        end
    end
end

set(gca, 'XTick', 1:nShells, 'XTickLabel', shellLabels, ...
    'FontSize', 12, 'Box', 'off', 'TickDir', 'out');
ylabel('CSF Signal (a.u.)');
xlabel('Distance from Vessel');
title(['CSF Signal — ' ROI ' — L+R averaged per subject']);
xlim([0.5 nShells+0.5]);
ylim([0 500]);

[~, p, ~, stats] = ttest(AllMeanB0(:,1), AllMeanB0(:,2));
fprintf('B0 shell1 vs shell2 (L+R averaged): t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);

%% calculating difference between pvsas vs. sas csf-mobility
