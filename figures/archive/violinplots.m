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
groupNames = {'m1_left_external', 'm1_internal'};


roiPairs = {
    {'m1_left_externaldonut.nii.gz', 'm1_right_externaldonut.nii.gz'}
    {'m1_left_internaldonut.nii.gz', 'm1_right_internaldonut.nii.gz'}

};

groupData = cell(1, length(groupNames));

for s = 1:length(subjects)
    subjID = subjects(s).name;
    subjPath = fullfile(dataDir, subjID);
    ROIsDir = fullfile(subjPath, 'ROIs');

    
        if strcmp(subjID, '20191029_Rec')
            fileList = dir(fullfile(subjPath, 'reoriented/', 'ADC_Thres150.mhd'));
                if isempty(fileList)
                    error('No matching files found: ADC_Thres150.mhd');
                end
            referenceScanPath = fullfile(fileList(1).folder, fileList(1).name);
            csfMapPath = metaImageRead(referenceScanPath);
            csf_data = csfMapPath;
        else
             csfMapPath = fullfile(subjPath, 'reoriented', 'masked_b0_ADC_mhd_thr150.0000.nii');
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
            
            if strcmp(subjID, '20191029_Rec')
                    roi_mask = permute(roi_mask > 0, [2 1 3]);  % swap x and y axes
            else
                    roi_mask = roi_mask > 0;
            end
            
            fprintf('Number of voxels in ROI: %d\n', nnz(roi_mask));

            values = csf_data(roi_mask);
            values = values(~isnan(values) & values > 0);

            fprintf('Raw voxels: %d | After filtering: %d\n', numel(csf_data(roi_mask)), numel(values));

            if ~isempty(values)
                meanVals(end+1) = mean(values);  
            end
        end


            if ~isempty(meanVals)
                subjectAvg = mean(meanVals);  % mean of 1 or 2 values
                groupData{g} = [groupData{g}; subjectAvg];

                if length(meanVals) < 2
                    fprintf('Only one ROI found for group %s in subject %s. Using available data.\n', groupNames{g}, subjID);
                end
            else
                fprintf('Skipping group %s for subject %s: no ROIs available.\n', groupNames{g}, subjID);
            end

    end
end

%% 

% Extract the two groups from the cell array
data1 = groupData{1}; 
data2 = groupData{2};  

% Find the number of pairs we can connect (minimum length)
nPairs = min(length(data1), length(data2));

% Create categorical group labels for violinplot
groupLabels = categorical([repmat("External", length(data1), 1); repmat("Internal", length(data2), 1)]);

% Combine data for violinplot
combinedData = [data1; data2];


%%

figure('Name', 'CSF Mobility', 'NumberTitle', 'off');
set(gcf, 'Color', 'w', 'Renderer', 'Painters');

% Plot violins (dots will be overplotted manually, so hide default dots)
violinplot(combinedData, groupLabels, 'ShowData', false);
hold on;

% Define jittered x positions for subject pairs
nPairs = length(data1);
jitterAmount = 0.1;
rng(1);  % for reproducible jitter
x1 = 1 + (rand(nPairs, 1) - 0.5) * jitterAmount;
x2 = 2 + (rand(nPairs, 1) - 0.5) * jitterAmount;

% Draw lines and dots
for i = 1:nPairs
    % Line
    plot([x1(i), x2(i)], [data1(i), data2(i)], 'Color', [0.5 0.5 0.5], 'LineWidth', 0.7);

    % Dots (circle markers)
    plot(x1(i), data1(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
    plot(x2(i), data2(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end

title('Mean CSF Mobility M1 — External vs. Internal');
ylabel('Mean ADC (mm^2/s)');
ylim([0 0.05]);
xticks([1 2]);
xticklabels(groupLabels);
hold off;

% 6.5478e-08
%% ttest

% Perform paired t-test
[~, p, ~, stats] = ttest(data1, data2);

% Display results
fprintf('Paired t-test M1: t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);

%% 

% %%mean test
% 
% % Assume data is an Nx2 matrix where column 1 is "left" and column 2 is "right"
% % Paste your data into a matrix first:
% data = [
%     0.0086, 0.0203;
%     0.0055, 0.0195;
%     0.0080, 0.0159;
%     0.0188, 0.0447;
%     0.0109, 0.0278;
%     0.0155, 0.0325;
%     0.0134, 0.0283;
%     0.0078, 0.0345;
%     0.0189, 0.0438;
%     0.0088, 0.0241;
%     0.0096, 0.0321
% ];




data = [
    0.0159846781753004, 0.0399827267974615;
    0.0115419207140803, 0.0455953143537045;
    0.0140413101762533, 0.0493310242891312;
    0.0234336145222187, 0.0425788201391697;
    0.0176491569727659, 0.0406129788607359;
    0.0170937594957650, 0.0413660537451506;
    0.0198024800047278, 0.0407384466379881;
    0.0260211210697889, 0.0495924241840839;
    0.0215244321152568, 0.0502001196146011;
    0.0143770580179989, 0.0316887414082885;
    0.0242174966260791, 0.0447199661284685
];

% % Logical vector: true if left is at least 20% less than right
is_20pct_less = data(:,1) < 0.8 * data(:,2);

% Show which rows pass the condition
disp(is_20pct_less);


%% run for M2
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
groupNames = {'m2_left_external', 'm2_internal'};

roiPairs = {
     {'m2_left_externaldonut.nii.gz', 'm2_right_externaldonut.nii.gz'}
     {'m2_left_internaldonut.nii.gz', 'm2_right_internaldonut.nii.gz'}

};

% Pre-define group names and their corresponding ROI pairs


groupData = cell(1, length(groupNames));

for s = 1:length(subjects)
    subjID = subjects(s).name;
    subjPath = fullfile(dataDir, subjID);
    ROIsDir = fullfile(subjPath, 'ROIs');

    
        if strcmp(subjID, '20191029_Rec')
            fileList = dir(fullfile(subjPath, 'reoriented/', 'ADC_Thres150.mhd'));
                if isempty(fileList)
                    error('No matching files found: ADC_Thres150.mhd');
                end
            referenceScanPath = fullfile(fileList(1).folder, fileList(1).name);
            csfMapPath = metaImageRead(referenceScanPath);
            csf_data = csfMapPath;
        else
             csfMapPath = fullfile(subjPath, 'reoriented', 'masked_b0_ADC_mhd_thr150.0000.nii');
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
            
            if strcmp(subjID, '20191029_Rec')
                    roi_mask = permute(roi_mask > 0, [2 1 3]);  % swap x and y axes
            else
                    roi_mask = roi_mask > 0;
            end
            
            fprintf('Number of voxels in ROI: %d\n', nnz(roi_mask));

            values = csf_data(roi_mask);
            values = values(~isnan(values) & values > 0);

            fprintf('Raw voxels: %d | After filtering: %d\n', numel(csf_data(roi_mask)), numel(values));

            if ~isempty(values)
                meanVals(end+1) = mean(values);  
            end
        end


            if ~isempty(meanVals)
                subjectAvg = mean(meanVals);  % mean of 1 or 2 values
                groupData{g} = [groupData{g}; subjectAvg];

                if length(meanVals) < 2
                    fprintf('Only one ROI found for group %s in subject %s. Using available data.\n', groupNames{g}, subjID);
                end
            else
                fprintf('Skipping group %s for subject %s: no ROIs available.\n', groupNames{g}, subjID);
            end

    end
end

%% 

% Extract the two groups from the cell array
data1 = groupData{1}; 
data2 = groupData{2};  

% Find the number of pairs we can connect (minimum length)
nPairs = min(length(data1), length(data2));

% Create categorical group labels for violinplot
groupLabels = categorical([repmat("External", length(data1), 1); repmat("Internal", length(data2), 1)]);

% Combine data for violinplot
combinedData = [data1; data2];


%%

figure('Name', 'CSF Mobility', 'NumberTitle', 'off');
set(gcf, 'Color', 'w', 'Renderer', 'Painters');

% Plot violins (dots will be overplotted manually, so hide default dots)
violinplot(combinedData, groupLabels, 'ShowData', false);
hold on;

% Define jittered x positions for subject pairs
nPairs = length(data1);
jitterAmount = 0.1;
rng(1);  % for reproducible jitter
x1 = 1 + (rand(nPairs, 1) - 0.5) * jitterAmount;
x2 = 2 + (rand(nPairs, 1) - 0.5) * jitterAmount;

% Draw lines and dots
for i = 1:nPairs
    % Line
    plot([x1(i), x2(i)], [data1(i), data2(i)], 'Color', [0.5 0.5 0.5], 'LineWidth', 0.7);

    % Dots (circle markers)
    plot(x1(i), data1(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
    plot(x2(i), data2(i), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end

title('Mean CSF Mobility M2 — External vs. Internal');
ylabel('Mean ADC (mm^2/s)');
ylim([0 0.05]);
xticks([1 2]);
xticklabels(groupLabels);
hold off;

% 6.5478e-08
%% ttest

data = ttest(data1, data2);
% Perform paired t-test
[~, p, ~, stats] = ttest(data1, data2);

% Display results
fprintf('Paired t-test M2: t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);

%% 

% %%mean test
% 
% % Assume data is an Nx2 matrix where column 1 is "left" and column 2 is "right"
% % Paste your data into a matrix first:


% % Logical vector: true if left is at least 20% less than right
is_20pct_less = data1 < 0.8 * data2;

% Show which rows pass the condition
disp(is_20pct_less);

