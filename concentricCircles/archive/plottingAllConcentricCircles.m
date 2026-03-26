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

y_limits = [0 0.06];
x_limits = [0 3];

subject_list = {
    '20191022_Reconstruction' 
    '20201020_Reconstruction'
    '20201111_Reconstruction' 
    '20191210_Reconstruction' 
    '20201019_Reconstruction'
    '20201110_Reconstruction'
}

AllMeanADC = {};
AllMeanB0  = {};


figure; hold on;
for k = 1:numel(subject_list)

subject_code = subject_list{k}
%% paths

subjPath                 = fullfile(project_directory, project_name, subject_code);
CCDir                   = fullfile(subjPath, '\', 'concentricCircles');
addpath(genpath(fullfile(project_directory, project_name, subject_code)));


    cd(CCDir);
            adcStruct = load(['meanCSFmobility_CC' ROI '_150_median.mat'], 'meanADC');
            meanADC = adcStruct.meanADC;
            b0Struct = load(['meanB0_CC' ROI '_150_median.mat'], 'meanB0');
            b0 = b0Struct.meanB0;
            
            nBins = numel(meanADC);
            binCenters = (1:nBins) * binWidth;
           hold on;
            
  % Plot individual subjects (light, thin lines)
    yyaxis left
    plot(binCenters, meanADC, 'b-', 'LineWidth', 0.5, 'Color', [0.5 0.7 1]);
    ylabel('csf-mobility');
    ylim(y_limits);
    xlim(x_limits);
    hold on;


    yyaxis right
    plot(binCenters, b0, '-', 'LineWidth', 0.5, 'Color', [1 0.85 0.5]);
    ylim([0 500]);
    ylabel('non-motionsensitized scan');
    xlim(x_limits);
            % ylabel('B0');   % if you want a right y-label

            xlabel('Dilation (mm)');
            title(['CSF ' ROI])


    AllMeanADC{k} = meanADC(:)';  % ensure row vector
    AllMeanB0{k}  = b0(:)';   % ensure row vector


end
% Stack into matrix (subjects x bins) and compute stats
ADC_matrix = cell2mat(AllMeanADC');   % fixed: use cell2mat
B0_matrix  = cell2mat(AllMeanB0');

AllSubjectsADC    = mean(ADC_matrix, 1);
AllSubjectsADCSTD = std(ADC_matrix, 0, 1);
AllSubjectsB0     = mean(B0_matrix, 1);
AllSubjectsB0STD  = std(B0_matrix, 0, 1);

upper   = AllSubjectsADC + AllSubjectsADCSTD;
lower   = AllSubjectsADC - AllSubjectsADCSTD;
upperB0 = AllSubjectsB0  + AllSubjectsB0STD;
lowerB0 = AllSubjectsB0  - AllSubjectsB0STD;

% Plot group mean + shading
yyaxis left
fill([binCenters fliplr(binCenters)], ...
     [upper fliplr(lower)], ...
     [0.5 0.7 1], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
plot(binCenters, AllSubjectsADC, 'b-', 'LineWidth', 2);
ylabel('csf-mobility');
ylim(y_limits);
xlim(x_limits);
% 
yyaxis right
fill([binCenters fliplr(binCenters)], ...
     [upperB0 fliplr(lowerB0)], ...
     [1 0.65 0], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
plot(binCenters, AllSubjectsB0, '-', 'LineWidth', 2, 'Color', [1 0.65 0]);  % fixed: explicit color
%ylim([0 1000]);
ylabel('non-motionsensitized scan');
xlim(x_limits);

xlabel('Dilation (mm)');
title(['CSF ' ROI]);


