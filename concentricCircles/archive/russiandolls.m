%%
% defining paths
project_directory = 'R:\- Gorter\- Personal folders\Fultz, N\';
project_name      = 'csfdonuts_lydiane'
scripts           = fullfile(project_directory, 'scripts', project_name);
%%params
binWidth = 0.45; % bins - probs same as your voxsize - mm
addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts)));

ROI = 'M2';
subject_list = {
'20191022_Reconstruction'
'20201020_Reconstruction'
'20201111_Reconstruction'
'20191210_Reconstruction'
'20201019_Reconstruction'
'20201110_Reconstruction'};

% Define the Russian doll radii
radii = [1, 2, 3]; % mm
nRadii = numel(radii);

% Colors for each shell
adcColors = [0.2 0.4 1;   % 1mm - dark blue
             0.5 0.7 1;   % 2mm - medium blue
             0.8 0.9 1];  % 3mm - light blue

b0Colors  = [1 0.5 0.1;   % 1mm - dark orange
             1 0.7 0.3;   % 2mm - medium orange
             1 0.9 0.6];  % 3mm - light orange

% Storage: each cell is [nSubjects x nRadii]
AllMeanADC_doll = zeros(numel(subject_list), nRadii);
AllMeanB0_doll  = zeros(numel(subject_list), nRadii);

for k = 1:numel(subject_list)
    subject_code = subject_list{k};

    subjPath = fullfile(project_directory, project_name, subject_code);
    CCDir    = fullfile(subjPath, 'concentricCircles');
    addpath(genpath(fullfile(project_directory, project_name, subject_code)));
    cd(CCDir);

    adcStruct = load(['meanCSFmobility_CC' ROI '_150_median.mat'], 'meanADC');
    meanADC   = adcStruct.meanADC;
    b0Struct  = load(['meanB0_CC' ROI '_150_median.mat'], 'meanB0');
    b0        = b0Struct.meanB0;

    nBins      = numel(meanADC);
    binCenters = (1:nBins) * binWidth;

    % For each radius, average all bins within that radius
    for r = 1:nRadii
        withinRadius = binCenters <= radii(r);
        if any(withinRadius)
            AllMeanADC_doll(k, r) = mean(meanADC(withinRadius));
            AllMeanB0_doll(k, r)  = mean(b0(withinRadius));
        else
            AllMeanADC_doll(k, r) = NaN;
            AllMeanB0_doll(k, r)  = NaN;
        end
    end
end

%% Compute group mean and SEM across subjects
groupMeanADC = median(AllMeanADC_doll, 1, 'omitnan');
groupSEMADC  = std(AllMeanADC_doll, 0, 1, 'omitnan') / sqrt(numel(subject_list));

groupMeanB0  = median(AllMeanB0_doll, 1, 'omitnan');
groupSEMB0   = std(AllMeanB0_doll, 0, 1, 'omitnan') / sqrt(numel(subject_list));

%% Russian Doll Plot
figure; hold on;

% --- Left axis: ADC ---
yyaxis left
for r = 1:nRadii
    % Individual subjects
    scatter(repmat(radii(r), numel(subject_list), 1), AllMeanADC_doll(:, r), ...
        40, 'o', 'MarkerEdgeColor', adcColors(r,:), 'MarkerFaceColor', adcColors(r,:), ...
        'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.6);
end
% Group mean ± SEM
errorbar(radii, groupMeanADC, groupSEMADC, 'b-o', ...
    'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'CapSize', 8);

ylabel('CSF-mobility (mean within radius)');
ylim([0 0.03]);

% --- Right axis: B0 ---
yyaxis right
for r = 1:nRadii
    scatter(repmat(radii(r), numel(subject_list), 1), AllMeanB0_doll(:, r), ...
        40, 's', 'MarkerEdgeColor', b0Colors(r,:), 'MarkerFaceColor', b0Colors(r,:), ...
        'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.6);
end
errorbar(radii, groupMeanB0, groupSEMB0, '-s', 'Color', [1 0.5 0], ...
    'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', [1 0.5 0], 'CapSize', 8);

ylabel('Non-motionsensitized scan (B0)');
ylim([0 1000]);

% --- Formatting ---
xticks(radii);
xticklabels({'≤1 mm', '≤2 mm', '≤3 mm'});
xlabel('Radius from ROI boundary');
title(['Russian Doll Plot — CSF ' ROI]);
xlim([0.5 3.5]);
hold off;