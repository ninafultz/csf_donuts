
clear; clc;
%% plot to show csf mobility ring around vessel and then SAS - M1 and M2

% Define paths
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name = 'csfdonuts_lydiane';
scripts = fullfile(project_directory, 'scripts');

addpath(genpath(fullfile(scripts, 'Violinplot-Matlab-master')));
addpath(genpath('/exports/gorter-hpc/users/ninafultz/scripts/spm12'));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, project_name, 'functions')));

% Get subject list
dataDir = fullfile(project_directory, project_name);
subjects = dir(fullfile(dataDir, '*Rec*'));
subjects = subjects([subjects.isdir]);

% Pre-define group names and their corresponding ROI pairs
groupNames = {'m1', 'm2', 'aca'};


roiPairs = {
    {'m1_left_internaldonut.nii.gz', 'm1_right_internaldonut.nii.gz'}    
    {'m2_left_internaldonut.nii.gz', 'm2_right_internaldonut.nii.gz'}
    {'aca_left_internaldonut.nii.gz', 'aca_right_internaldonut.nii.gz'}

};

groupData = cell(1, length(groupNames));

for s = 1:length(subjects)
    subjID = subjects(s).name;
    subjPath = fullfile(dataDir, subjID);
    ROIsDir = fullfile(subjPath, 'ROIs');

    
        if strcmp(subjID, '20191029_Rec')
            fileList = dir(fullfile(subjPath, 'reoriented/', 'FA_Thresh150.mhd'));
                if isempty(fileList)
                    error('No matching files found: FA_Thresh150.mhd');
                end
            referenceScanPath = fullfile(fileList(1).folder, fileList(1).name);
            csfMapPath = metaImageRead(referenceScanPath);
            csf_data = csfMapPath;
        else
             csfMapPath = fullfile(subjPath, 'reoriented', ...
                 'maskedFA_mhd_thr150.0000.nii');
             % Load CSF mobility map
            csf_data = niftiread(csfMapPath);
        end


    for g = 1:length(groupNames)
        roiPair = roiPairs{g};
        meanVals = [];

        for r = 1:2
            roiName = roiPair{r};
            roiFile = fullfile(ROIsDir, roiName);

            % Try fallback to .nii if .nii.gz not found
            if ~isfile(roiFile)
                roiNameAlt = regexprep(roiName, '.nii.gz$', '.nii');
                roiFile = fullfile(ROIsDir, roiNameAlt);
                if ~isfile(roiFile)
                    fprintf('Missing ROI %s for subject %s\n', roiName, subjID);
                    continue;
                end
            end
 
            roi_mask = niftiread(roiFile);            
            
            %% 20191029 is not in nifti format, so had to permute
            if strcmp(subjID, '20191029_Rec')
                    roi_mask = permute(roi_mask > 0, [2 1 3]);  % swap x and y axes
            else
                    roi_mask = roi_mask > 0;
            end
            
            fprintf('Number of voxels in ROI: %d\n', nnz(roi_mask));

            values = csf_data(roi_mask);
            values = values(values > 0); % some of the ROIs have
                                         % zeros because of how ROI was drawn
            
            fprintf('Raw voxels: %d | After filtering: %d\n', ...
                numel(csf_data(roi_mask)), numel(values));

            if ~isempty(values)
                meanVals(end+1) = mean(values);  
            end
        end


            if ~isempty(meanVals)
                subjectAvg = mean(meanVals);  % mean of 1 or 2 values
                groupData{g} = [groupData{g}; subjectAvg];

                if length(meanVals) < 2
                    fprintf('Only one ROI found for group %s in subject %s. Using available data.\n', ...
                        groupNames{g}, subjID);
                end
            else
                fprintf('Skipping group %s for subject %s: no ROIs available.\n', ...
                    groupNames{g}, subjID);
            end

    end
end

%% extracting data

data1 = groupData{1}; 
data2 = groupData{2};  
data3 = groupData{3};  

% Create categorical group labels for violinplot LOL BYE THE WAY ITS
% ALPHABETICAL
groupLabels = categorical([
    repmat("M1", length(data1), 1);
    repmat("M2", length(data2), 1);
    repmat("ACA", length(data3), 1)
], {'M1','M2','ACA'});   % <— enforce order

% Combine data for violinplot
combinedData = [data1; data2; data3];


%% plot

figure('Name', 'CSF Mobility', 'NumberTitle', 'off');
set(gcf, 'Color', 'w', 'Renderer', 'Painters');

% Plot violins
violinplot(combinedData, groupLabels, 'ShowData', false);
hold on;

% Define jittered x positions for subject pairs
nPairs = length(data1);
jitterAmount = 0.1;
rng(1);  % for reproducible jitter
x1 = 1 + (rand(nPairs, 1) - 0.5) * jitterAmount;
x2 = 2 + (rand(nPairs, 1) - 0.5) * jitterAmount;
x3 = 3 + (rand(nPairs, 1) - 0.5) * jitterAmount;

% Draw lines and dots
for i = 1:nPairs
    % Line
    plot([x1(i), x2(i), x3(i)], [data1(i), data2(i), data3(i)], 'Color', [0.5 0.5 0.5], ...
        'LineWidth', 0.7);

    % Dots (circle markers)
    plot(x1(i), data1(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
    plot(x2(i), data2(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
    plot(x3(i), data3(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end

title('Mean FA Mobility across Arteries');
ylabel('Mean ADC (mm^2/s)');
ylim([0.5 0.8]);
%xticklabels({'M1', 'M2', 'ACA'});
hold off;

%% ttest


% Perform paired t-test (bonferonni corrected 3 times)

[~, p12] = ttest(data1, data2);
[~, p13] = ttest(data1, data3);
[~, p23] = ttest(data2, data3);

% Bonferroni-corrected threshold
bf = 0.05 / 3;  % 0.0167

% Check significance
sig12 = p12 < bf;
sig13 = p13 < bf;
sig23 = p23 < bf;

% Print results
fprintf('Bonferroni threshold: %.4f\n', bf);
fprintf('data1 vs data2: p = %.5f, significant? %d\n', p12, sig12);
fprintf('data1 vs data3: p = %.5f, significant? %d\n', p13, sig13);
fprintf('data2 vs data3: p = %.5f, significant? %d\n', p23, sig23);

% Bonferroni threshold: 0.0167
% data1 vs data2: p = 0.00675, significant? 1
% data1 vs data3: p = 0.37426, significant? 0
% data2 vs data3: p = 0.12735, significant? 0
