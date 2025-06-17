function t2star_venogram(project_directory, project_name, subject_code);

%t2star_venogram

% Define the switch block for subject-specific operations
    switch subject_code
        case 'csfdonut01'
            subject_code      =  '';
            common_prefix     = 'T2star_3D_0.6_lowPNS';
        case 'test'
            subject_code      =  'test01_angiogramvenogram';
            common_prefix     = 'T2star_3D_0.6_lowPNS';
        otherwise
            % Handle any default actions or errors
            warning('Subject not recognized or handled');
    end
    
    
regDir         = fullfile(project_directory, project_name, subject_code, 'reg');
fa             = fullfile(project_directory, project_name, subject_code, 'fa');
adc            = fullfile(project_directory, project_name, subject_code, 'adc');
reoriented     = fullfile(project_directory, project_name, subject_code, 'reoriented');
biasfield      = fullfile(project_directory, project_name, subject_code, 'biasfield');
veno_dir       = fullfile(project_directory, project_name, subject_code, 'veno');
toolbox        = fullfile(project_directory, 'scripts', 'toolbox');
functions_path = fullfile(project_directory, 'scripts', project_name, 'functions');
par_path       = fullfile(project_directory, project_name, subject_code, 'par');


% Add necessary paths
addpath(functions_path)
addpath(genpath(toolbox));

%% Gather Echo Files Dynamically
% Collect all files matching the common prefix and echo pattern
nifti_files = dir(fullfile(veno_dir, [common_prefix '_e*_ph.nii.gz']));

% Ensure files are sorted by echo index
[~, idx] = sort({nifti_files.name}); % Sort filenames alphabetically
nifti_files = nifti_files(idx);

% Display matched files
disp('Matched Echo Files:');
disp({nifti_files.name});

cd(par_path)
[img_data, ~ ] = import_parrec_special_WT2_LH(1, '*'); % loads the raw data of all echoes (NOT YET MASKED!)
 
img_data_flipped = flip(img_data, 1);

    figure;
    imshow3Dfull(img_data_flipped(:,:,:,2)); % Adjust the intensity range as needed
    colorbar;
    title('T2* Map (ms)');
    xlabel('X');
    ylabel('Y');
%% Load Echo Files
% Preallocate cell array for echo data
numEchoes = numel(nifti_files);
echoData  = cell(numEchoes, 1);

for i = 1:numEchoes
    % Load each echo file
    echoPath = fullfile(nifti_files(i).folder, nifti_files(i).name);
    echoData{i} = niftiread(echoPath);
end

%% Define Echo Times
% Define echo times (ensure these match your acquisition parameters)
echo_times = extract_echo_times(nifti_files(1).folder, common_prefix)

%% Calculate T2* Map
% Preallocate T2* map
imageDims = size(echoData{1});
T2StarMap = zeros(imageDims);

% Compute T2* voxel-wise
for x = 1:imageDims(1)
    for y = 1:imageDims(2)
        for z = 1:imageDims(3)
            % Extract signal intensities for all echoes
            signal = zeros(numEchoes, 1);
            for i = 1:numEchoes
                signal(i) = img_data_flipped(x, y, z, i);
            end

            % Skip fitting if all signals are zero
            if all(signal == 0)
                T2StarMap(x, y, z) = NaN;
                continue;
            end

            % Perform logarithmic linear regression
            logSignal = log(signal);
            p = polyfit(echo_times, logSignal, 1); % Fit: log(S) = -TE/T2* + log(S0)

            % Extract T2* from the slope
            T2StarMap(x, y, z) = -1 / p(1);
        end
    end
end

%% Visualize T2* Map
% Display a slice from the T2* map

figure;
imshow3Dfull(T2StarMap, [0 50]); % Adjust the intensity range as needed
colorbar;
title('T2* Map (ms)');
xlabel('X');
ylabel('Y');


%% saving T2* map 
niftiFilePath = fullfile(veno_dir, 'combinedEchoes_all_venogram.nii');
echoData = niftiread(niftiFilePath);

% Load the NIfTI header information
niftiInfo = niftiinfo(niftiFilePath);

% Ensure data type matches the averagedVolume
niftiInfo.Datatype = class(echoData);

% Update the NIfTI header information to match the averaged volume size
niftiInfo.ImageSize = size(echoData);

% Define the output filename for the averaged volume
outputFile = fullfile(veno_dir, 'T2star_venogram.nii');

T2StarMap = single(T2StarMap); % Convert data to int16

% Write the averaged volume to a new NIfTI file
niftiwrite(T2StarMap, outputFile, niftiInfo);

% Check if the output file exists and matches the intended dimensions
if exist(outputFile, 'file')
    disp('volume saved successfully!');
else
    disp('Failed to save volume.');
end
end 