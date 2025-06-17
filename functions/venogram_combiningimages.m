function venogram_combiningimages(project_directory, project_name, subject_code);




% Define the switch block for subject-specific operations
    switch subject_code
        case 'csfdonut01'
            subject_code =  '';
        case 'test'
            subject_code =  'test01_angiogramvenogram';
        otherwise
            % Handle any default actions or errors
            warning('Subject not recognized or handled');
    end

%% Paths
veno_dir       = fullfile(project_directory, project_name, subject_code, 'veno');
toolbox        = fullfile(project_directory, 'scripts', 'toolbox');

addpath(genpath(toolbox));

%% merging echoes


% Define the base filenames for the echoes (without extension)

echoFiles = {
    'T2star_3D_0.6_lowPNS_e1_ph.nii';
    'T2star_3D_0.6_lowPNS_e2_ph.nii';
    'T2star_3D_0.6_lowPNS_e3_ph.nii';
    'T2star_3D_0.6_lowPNS_e4_ph.nii';
    'T2star_3D_0.6_lowPNS_e5_ph.nii';
    'T2star_3D_0.6_lowPNS_e6_ph.nii'
};

% Preallocate cell array for echo data
echoData = cell(length(echoFiles), 1);

% Loop through each echo file
for i = 1:length(echoFiles)
    % Full path to the compressed .nii.gz file
    niiFile = fullfile(veno_dir, echoFiles{i});
    
    % Read the NIfTI file
    echoData{i} = niftiread(niiFile);
end

% Access echoes from the cell array (example)
echo1 = echoData{1};
echo2 = echoData{2};
echo3 = echoData{3};
echo4 = echoData{4};
echo5 = echoData{5};
echo6 = echoData{6};

% Combine the echoes into a 4D volume
combinedVolume = cat(4, echo1, echo2, echo3, echo4, echo5, echo6);

% Calculate the averaged volume
averagedVolume = mean(combinedVolume, 4);

% Load the NIfTI header information from one of the input files
niftiInfo = niftiinfo(niiFile);

% Ensure data type matches the averagedVolume
niftiInfo.Datatype = class(averagedVolume);

% Update the NIfTI header information to match the averaged volume size
niftiInfo.ImageSize = size(averagedVolume);

% Define the output filename for the averaged volume
outputFile = fullfile(veno_dir, 'combinedEchoes_all_venogram.nii');

% Write the averaged volume to a new NIfTI file
niftiwrite(averagedVolume, outputFile, niftiInfo);

% Check if the output file exists and matches the intended dimensions
if exist(outputFile, 'file')
    disp('Combined and averaged volume saved successfully!');
else
    disp('Failed to save the combined and averaged volume.');
end
%% 
end


