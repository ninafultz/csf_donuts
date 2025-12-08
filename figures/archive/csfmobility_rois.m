% defining paths 
project_directory = '/exports/gorter-hpc/users/ninafultz/'
project_name      = 'csf_donut'
subject_code      = 'csfdonut01'

scripts           = fullfile(project_directory, 'scripts');
addpath(genpath(fullfile(scripts, 'csf_donut')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts, 'functions')));
addpath(genpath(fullfile(project_directory, project_name, subject_code)));

subjPath          = fullfile(project_directory, project_name, subject_code);
ROIs                 = fullfile(subjPath, 'ROIs');
reoriented           = fullfile(subjPath, 'reoriented');
%% ROIs_plottingT2_andCSFmobility.m


% Load paths
ROIs_dir = fullfile(subjPath, 'ROIs');
reoriented_dir = fullfile(subjPath, 'reoriented');

% Load the images
ADC = niftiread(fullfile(reoriented_dir, 'maskedADC_properorientation.nii'));
FA = niftiread(fullfile(reoriented_dir, 'maskedFA_properorientation.nii'));
T2 = niftiread(fullfile(reoriented_dir, 'T2_map_CSF_8echoes_notfixed_oct08_2to68_tocsfstream.nii'));
T2_info = niftiinfo(fullfile(reoriented_dir, 'T2_map_CSF_8echoes_notfixed_oct08_2to68_tocsfstream.nii'));
% Determine size of the T2 image
T2_size = T2_info.ImageSize;
%% 


%% 
% Load ROI NIfTI files
ROI_files = dir(fullfile(ROIs_dir, 'straightline.nii')); % Adjust pattern as needed

if isempty(ROI_files)
    error('No ROI files found. Check the directory or filename pattern.');
end

% Loop through each ROI
for i = 1:length(ROI_files)
    % Load the ROI
    ROI_path = fullfile(ROI_files(i).folder, ROI_files(i).name);
    ROI = niftiread(ROI_path);

    % Resample the ROI to match T2 resolution
    ROI_resampled = imresize3(ROI, T2_size, 'nearest'); % Binary preservation
    ROI_resampled = ROI_resampled > 0;

    % Apply the resampled ROI to the T2 image
    T2_masked(ROI_resampled) = T2(ROI_resampled);


        % Initialize variables
        ADCtubeValues = []; % Initialize as empty to store tube values

        % Extract ROI indices where ROI equals 1
        [tubeX, tubeY, tubeZ] = ind2sub(size(ROI), find(ROI > 0));

        % Sort spatially to follow the tube's path
        [~, sortIdx] = sortrows([tubeX, tubeY, tubeZ]); % Sort by coordinates

        % Extract ADC values at these positions
        adcValues = ADC(sub2ind(size(ADC), tubeX, tubeY, tubeZ)); % Get ADC values
        ADCtubeValues = adcValues(sortIdx); % Reorder the ADC values based on sorting
       
        % Initialize variables
        FAtubeValues = []; % Initialize as empty to store tube values

        % Extract ROI indices where ROI equals 1
        [tubeX, tubeY, tubeZ] = ind2sub(size(ROI), find(ROI > 0));

        % Sort spatially to follow the tube's path
        [~, sortIdx] = sortrows([tubeX, tubeY, tubeZ]); % Sort by coordinates
        
        % Extract ADC values at these positions
        faValues = FA(sub2ind(size(ADC), tubeX, tubeY, tubeZ)); % Get ADC values
        FAtubeValues = faValues(sortIdx); % Reorder the ADC values based on sorting

                % Initialize variables
        T2tubeValues = []; % Initialize as empty to store tube values

        % Extract ROI indices where ROI equals 1
        [tubeX, tubeY, tubeZ] = ind2sub(size(ROI_resampled), find(ROI_resampled > 0));

        % Sort spatially to follow the tube's path
        [~, sortIdx] = sortrows([tubeX, tubeY, tubeZ]); % Sort by coordinates

        % Extract ADC values at these positions
        t2Values = T2(sub2ind(size(T2), tubeX, tubeY, tubeZ)); % Get ADC values
        T2tubeValues = t2Values(sortIdx); % Reorder the ADC values based on sorting
        
        
        % Plot the intensity values along the tube
        figure;
        subplot(3,1,1);
        plot(ADCtubeValues, 'LineWidth', 2); hold on
        scatter(1:length(ADCtubeValues), ADCtubeValues, 50, 'r', 'filled', 'DisplayName', 'Scatter Points');
        xlabel('Tube Position (arbitrary units)');
        ylabel('ADC Intensity');
        title('ADC Intensity Values Along the Tube');
        grid on;
        xlabel('Tube Position (arbitrary units)');
        ylabel('ADC Intensity');
        title('ADC Intensity Values Along the Tube');
        grid on;

        subplot(3,1,2);
        plot(FAtubeValues, 'LineWidth', 2); hold on
        scatter(1:length(FAtubeValues), FAtubeValues, 50, 'r', 'filled', 'DisplayName', 'Scatter Points');
        xlabel('Tube Position (arbitrary units)');
        ylabel('FA Intensity');
        title('FA Intensity Values Along the Tube');
        grid on;
        xlabel('Tube Position (arbitrary units)');
        ylabel('FA Intensity');
        title('FA Intensity Values Along the Tube');
        grid on;

        
                subplot(3,1,3);
        plot(T2tubeValues, 'LineWidth', 2); hold on
        scatter(1:length(T2tubeValues), T2tubeValues, 50, 'r', 'filled', 'DisplayName', 'Scatter Points');
        xlabel('Tube Position (arbitrary units)');
        ylabel('T2 Intensity');
        title('T2Intensity Values Along the Tube');
        grid on;
    
   
    % Save the plot (optional)
    % saveas(gcf, fullfile(reoriented_dir, ['VoxelValues_' ROI_files(i).name '.png']));
end


%% 

%find when roi and then plot

% Combine ADC map and ROI for visualization
combined_ADC = ADC; % Copy ADC map
combined_ADC(~ROI) = 0; % Apply mask

figure;
% Visualize in 3D
imshow3Dfull(ADC); %292
title('ADC Map with ROI Mask');

figure;
% Visualize in 3D
imshow3Dfull(ROI); %292
title('ADC Map with ROI Mask');

