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

% ── Build 4-column matrix: L_s1 | R_s1 | L_s2 | R_s2 ────────────────────
mat4_ADC = [AllMeanADC_L(:,1), AllMeanADC_R(:,1), AllMeanADC_L(:,2), AllMeanADC_R(:,2)];
mat4_B0  = [AllMeanB0_L(:,1),  AllMeanB0_R(:,1),  AllMeanB0_L(:,2),  AllMeanB0_R(:,2)];

xPos    = [1, 2, 4, 5];   % gap of 1 between L/R within shell, gap of 2 between shells
grpLbls = {'L 0–1.5', 'R 0–1.5', 'L 1.5–3', 'R 1.5–3'};

% Jitter for each of the 4 columns
rng(1);
xJit_ADC = zeros(nSubjects, 4);
xJit_B0  = zeros(nSubjects, 4);
for c = 1:4
    xJit_ADC(:,c) = xPos(c) + (rand(nSubjects,1) - 0.5) * 0.07;
    xJit_B0(:,c)  = xPos(c) + (rand(nSubjects,1) - 0.5) * 0.07;
end

%% ── Figure 1: CSF Mobility ───────────────────────────────────────────────
figure('Name', ['CSF Mobility — ' ROI], 'NumberTitle', 'off');
set(gcf, 'Color', 'w', 'Renderer', 'Painters');
hold on;

% Draw violins then shift them to xPos
vp = violinplot(mat4_ADC, grpLbls, 'ShowData', false);
for c = 1:4
    offset = xPos(c) - c;
    vp(c).ViolinPlot.XData      = vp(c).ViolinPlot.XData  + offset;
    vp(c).MedianPlot.XData(:)   = xPos(c);
    vp(c).BoxPlot.XData         = vp(c).BoxPlot.XData     + offset;
    vp(c).WhiskerPlot.XData     = vp(c).WhiskerPlot.XData + offset;
    vp(c).ScatterPlot.XData(:)  = xPos(c);
end

% Shade shell groups
yl = ylim;
fill([0.5 2.5 2.5 0.5], [yl(1) yl(1) yl(2) yl(2)], [0.90 0.90 0.90], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.3);
fill([3.5 5.5 5.5 3.5], [yl(1) yl(1) yl(2) yl(2)], [0.90 0.90 0.90], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.3);
text(1.5, yl(2), '0–1.5 mm', 'HorizontalAlignment', 'center', ...
    'FontSize', 9, 'Color', [0.4 0.4 0.4]);
text(4.5, yl(2), '1.5–3 mm', 'HorizontalAlignment', 'center', ...
    'FontSize', 9, 'Color', [0.4 0.4 0.4]);

for i = 1:nSubjects
    col = subjectCols(i,:);

    % dotted line: L–R within shell 1
    plot(xJit_ADC(i,[1 2]), mat4_ADC(i,[1 2]), ':', ...
        'Color', [col 0.35], 'LineWidth', 2);
    % dotted line: L–R within shell 2
    plot(xJit_ADC(i,[3 4]), mat4_ADC(i,[3 4]), ':', ...
        'Color', [col 0.35], 'LineWidth', 2);
end

% Dots: circles = Left (cols 1,3), squares = Right (cols 2,4)
leftCols  = [1 3];
rightCols = [2 4];
for i = 1:nSubjects
    col = subjectCols(i,:);
    for c = leftCols
        if ~isnan(mat4_ADC(i,c))
            plot(xJit_ADC(i,c), mat4_ADC(i,c), 'o', ...
                'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', ...
                'MarkerSize', 6, 'LineWidth', 0.2);
        end
    end
    for c = rightCols
        if ~isnan(mat4_ADC(i,c))
            plot(xJit_ADC(i,c), mat4_ADC(i,c), 's', ...
                'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', ...
                'MarkerSize', 6, 'LineWidth', 0.2);
        end
    end
end

set(gca, 'XTick', xPos, 'XTickLabel', grpLbls, ...
    'FontSize', 12, 'Box', 'off', 'TickDir', 'out');
ylabel('CSF Mobility (mm²/s)');
xlabel('Distance from Vessel');
title(['CSF Mobility — ' ROI ' — L & R per shell']);
xlim([0.5 5.5]);

% Legend
hSubj = arrayfun(@(i) plot(nan, nan, '-', 'Color', subjectCols(i,:), ...
    'LineWidth', 1.5), 1:nSubjects, 'UniformOutput', true);
hL_mk = plot(nan, nan, 'ko', 'MarkerFaceColor', [0.4 0.4 0.4], 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
hR_mk = plot(nan, nan, 'ks', 'MarkerFaceColor', [0.4 0.4 0.4], 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
hLline = plot(nan, nan, 'k-',  'LineWidth', 2);
hRline = plot(nan, nan, 'k--', 'LineWidth', 2);
hLRline= plot(nan, nan, 'k:',  'LineWidth', 2);
allHandles = [hSubj(:)', hL_mk, hR_mk, hLRline];
allLabels  = [legendEntries(:)', {'Left (circle)', 'Right (square)', 'L–R within shell'}];
legend(allHandles, allLabels, 'Location', 'eastoutside', 'FontSize', 7);

