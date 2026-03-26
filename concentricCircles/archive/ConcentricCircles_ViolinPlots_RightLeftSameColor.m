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

% ── Subject colours ───────────────────────────────────────────────────────
subjectCols = lines(nSubjects);

legendEntries = cellfun(@(s) s(1:8), subject_list, 'UniformOutput', false);

% ── Build pooled matrices for violins: (2*nSubjects) x nShells ────────────
% rows 1:nSubjects = Left, rows nSubjects+1:end = Right
matADC = [AllMeanADC_L; AllMeanADC_R];
matB0  = [AllMeanB0_L;  AllMeanB0_R];

% ── Jitter — L and R get separate jitter within same violin ───────────────
rng(1);
xJitter_L = zeros(nSubjects, nShells);
xJitter_R = zeros(nSubjects, nShells);
for s = 1:nShells
    xJitter_L(:,s) = s + (rand(nSubjects,1) - 0.5) * 0.07;
    xJitter_R(:,s) = s + (rand(nSubjects,1) - 0.5) * 0.07;
end

%% ── Figure 1: CSF Mobility ───────────────────────────────────────────────
figure('Name', ['CSF Mobility — ' ROI], 'NumberTitle', 'off');
set(gcf, 'Color', 'w', 'Renderer', 'Painters');
hold on;

violinplot(matADC, shellLabels, 'ShowData', false);

% Per subject: lines connecting L across shells, R across shells,
% and L-R within each shell — all in subject color
for i = 1:nSubjects
    col = subjectCols(i,:);

    % connect L shell1 → L shell2
    plot(xJitter_L(i,:), AllMeanADC_L(i,:), '-', ...
        'Color', [col 0.5], 'LineWidth', 1.0);
    % connect R shell1 → R shell2
    plot(xJitter_R(i,:), AllMeanADC_R(i,:), '--', ...
        'Color', [col 0.5], 'LineWidth', 1.0);
    % connect L-R within each shell
    for s = 1:nShells
        plot([xJitter_L(i,s), xJitter_R(i,s)], ...
             [AllMeanADC_L(i,s), AllMeanADC_R(i,s)], ':', ...
             'Color', [col 0.35], 'LineWidth', 0.7);
    end
end

% Dots — circles for L, squares for R
for i = 1:nSubjects
    col = subjectCols(i,:);
    for s = 1:nShells
        if ~isnan(AllMeanADC_L(i,s))
            plot(xJitter_L(i,s), AllMeanADC_L(i,s), 'o', ...
                'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', ...
                'MarkerSize', 6, 'LineWidth', 0.5);
        end
        if ~isnan(AllMeanADC_R(i,s))
            plot(xJitter_R(i,s), AllMeanADC_R(i,s), 's', ...
                'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', ...
                'MarkerSize', 6, 'LineWidth', 0.5);
        end
    end
end

set(gca, 'XTick', 1:nShells, 'XTickLabel', shellLabels, ...
    'FontSize', 12, 'Box', 'off', 'TickDir', 'out');
ylabel('CSF Mobility (mm²/s)');
xlabel('Distance from Vessel');
title(['CSF Mobility — ' ROI ' — L & R per shell']);
xlim([0.5 nShells+0.5]);

hSubj = arrayfun(@(i) plot(nan, nan, 'o-', 'Color', subjectCols(i,:), ...
    'MarkerFaceColor', subjectCols(i,:), 'MarkerEdgeColor', 'none', ...
    'MarkerSize', 5), 1:nSubjects, 'UniformOutput', true);   % returns 1 x nSubjects

hL_mk = plot(nan, nan, 'ko', 'MarkerFaceColor', [0.4 0.4 0.4], ...
    'MarkerEdgeColor', 'w', 'MarkerSize', 6);
hR_mk = plot(nan, nan, 'ks', 'MarkerFaceColor', [0.4 0.4 0.4], ...
    'MarkerEdgeColor', 'w', 'MarkerSize', 6);

allHandles  = [hSubj(:)', hL_mk, hR_mk];          % force everything to row
allLabels   = [legendEntries(:)', {'Left', 'Right'}];

legend(allHandles, allLabels, 'Location', 'eastoutside', 'FontSize', 7);


[~, p, ~, stats] = ttest(AllMeanADC_L(:,1), AllMeanADC_L(:,2));
fprintf('ADC L shell1 vs shell2: t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);
[~, p, ~, stats] = ttest(AllMeanADC_R(:,1), AllMeanADC_R(:,2));
fprintf('ADC R shell1 vs shell2: t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);

