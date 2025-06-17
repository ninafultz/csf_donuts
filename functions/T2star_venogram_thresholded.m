function T2star_venogram_thresholded(project_directory, project_name, subject_code);

reoriented     = fullfile(project_directory, project_name, subject_code, 'reoriented');
veno_dir       = fullfile(project_directory, project_name, subject_code, 'veno');
toolbox        = fullfile(project_directory, 'scripts', 'toolbox');
functions_path = fullfile(project_directory, 'scripts', project_name, 'functions');

toolbox        = fullfile(project_directory, 'scripts', 'toolbox');
addpath(genpath(toolbox));
%% Load T2* venogram
% Full path to the T2* venogram file
niiFile = fullfile(reoriented, 'T2star_venogram_to_B0_properOrientation.nii');

% Read the NIfTI file
T2StarData = niftiread(niiFile); % Load voxel data
niiInfo = niftiinfo(niiFile); % Get metadata

%% Thresholding parameters
T2StarThreshold_ms = 30; % Threshold in milliseconds

% Create a binary mask for veins where the 90th percentile is below the threshold
veins = T2StarData < T2StarThreshold_ms;


figure;
imshow3Dfull(T2StarData, [0 30]); % Adjust the intensity range as needed
colorbar;
title('T2* Map (ms)');
xlabel('X');
ylabel('Y');

% Apply threshold: retain values below the threshold, set others to 0
thresholdedData = T2StarData;
thresholdedData(T2StarData >= T2StarThreshold_ms) = 0;

figure;
imshow3Dfull(thresholdedData, [0 30]); % Adjust the intensity range as needed
colorbar;
title('T2* Map (ms)');
xlabel('X');
ylabel('Y');
%% saving out nifti



%% 
% Define the output filename for the averaged volume
niftiFilePath = fullfile(reoriented, 'T2star_venogram_to_B0_properOrientation.nii');
echoData = niftiread(niftiFilePath);
% Load the NIfTI header information
niftiInfo = niftiinfo(niftiFilePath);

% Ensure data type matches the averagedVolume
niftiInfo.Datatype = class(echoData);

% Update the NIfTI header information to match the averaged volume size
niftiInfo.ImageSize = size(echoData);

% Define the output filename for the averaged volume
outputFile = fullfile(reoriented, 'T2star_veins_thresholded30.nii');

% Ensure thresholdedData is of the same data type as echoData
thresholdedData = cast(thresholdedData, class(echoData)); 

% Write the thresholded volume to a new NIfTI file
niftiwrite(thresholdedData, outputFile, niftiInfo);

disp(['Thresholded NIfTI file saved to: ' outputFile]);

end

