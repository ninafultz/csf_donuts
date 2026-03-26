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
project_name      = 'csfdonuts_lydiane'
scripts           = fullfile(project_directory, 'scripts', project_name);

%%params
voxSize = 0.45; % voxel size mm
maxDist = 10; % distance away from vessel - mm 
binWidth = 0.45; % bins - probs same as your voxsize - mm

addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts)));

CCDir = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\concentricCircleResults';

ROIs = {'M2'};
dilationDiameter = 1:10;
voxSize = 0.45;
% binCenters = (1:length(dilationDiameter(:))) * voxSize;
binCenters = (0:length(dilationDiameter(:))-1) * voxSize;
for r = 1:numel(ROIs)
    ROI = ROIs{r};
     cd(CCDir);
    load(['allCSFmobilityLydiane' ROI '_Median_combined_manuallycorrected.mat']);
    load(['allB0Lydiane' ROI '_Median_combined_manuallycorrected.mat']);

    %% Normalize each subject by their own peak
    % averageADC_MCA is nSubjects x nBins
    peakADC = max(averageADC_MCA, [], 2);   % nSubjects x 1 — peak per subject
    peakB0  = max(averageCSF_MCA, [], 2);

    % peakADC = averageADC_MCA(:, 1);   % nSubjects x 1 — first value per subject
    % peakB0  = averageCSF_MCA(:, 1);

    normADC = averageADC_MCA ./ peakADC;    % each row divided by its own peak
    normB0  = averageCSF_MCA ./ peakB0;

    %% Mean and std across subjects
    % meanADC = mean(normADC, 1);
    % stdADC  = std(normADC, 0, 1);
    % meanB0  = mean(normB0, 1);
    % stdB0   = std(normB0, 0, 1);

    meanADC = mean(normADC, 1);
stdADC  = std(normADC, 0, 1);
meanB0  = mean(normB0, 1);
stdB0   = std(normB0, 0, 1);

    upper   = meanADC + stdADC;
    lower   = meanADC - stdADC;
    upperB0 = meanB0  + stdB0;
    lowerB0 = meanB0  - stdB0;

    %% Plot
    figure('Name', ['CSF Mobility Normalized — ' ROI], 'NumberTitle', 'off');
    set(gcf, 'Color', 'w', 'Renderer', 'painters');
    hold on;

    yyaxis left
    % Individual subject traces
    plot(binCenters, normADC', '-', 'LineWidth', 1, 'Color', [0.2 0.4 1 0.2]);
    % Std shading
    fill([binCenters fliplr(binCenters)], [upper fliplr(lower)], ...
         [0.6 0.7 1], 'EdgeColor', 'none', 'FaceAlpha', 0.4); hold on
    % Mean line
    plot(binCenters, meanADC, 'b-', 'LineWidth', 2);
    ylabel(['CSF-mobility (normalized to peak): ' ROI]);
    %ylim([0.5 1.1]);
    xlim([0 3]);

    yyaxis right
    fill([binCenters fliplr(binCenters)], [upperB0 fliplr(lowerB0)], ...
         [1 0.7 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    plot(binCenters, meanB0, 'r-', 'LineWidth', 2);
    ylim([0.5 1.1]);
    ylabel(['Non-motion-sensitized (normalized to peak): ' ROI]);

    xlabel('Distance from vessel (mm)');
    title(['CSF Mobility — Peak Normalized — ' ROI]);

end