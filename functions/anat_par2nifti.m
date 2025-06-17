function anat_par2nifti(subjPath);

regDir         = fullfile(subjPath , 'reg');
anat_dir       = fullfile(subjPath, 'anat');
par_path       = fullfile(subjPath, 'par');

%% saving T2* map 

% Define the directory and file pattern
filePattern = fullfile(anat_dir, '*_3dt1_0.9mm*.nii.gz');

% Find matching files
matchingFiles = dir(filePattern);

% Check the number of matching files
if isempty(matchingFiles)
    error('No files found matching the pattern: %s', filePattern);
elseif length(matchingFiles) > 1
    warning('Multiple files found matching the pattern. Loading the first one.');
end

% Load the first matching file
firstFilePath = fullfile(matchingFiles(1).folder, matchingFiles(1).name);
echoData = niftiread(firstFilePath);

% Define the output filename for the averaged volume
outputFile = fullfile(anat_dir, '3dT1_0.9mm.nii');

    source          = firstFilePath;
    destination     = fullfile(anat_dir, '3dT1_0.9mm.nii');
    
    % Copy the file
    disp('copying anatomical to reg folder!');
    copyfile(source, destination);
    
    source          = firstFilePath;
    destination     = fullfile(regDir, '3dT1_0.9mm.nii');
    
    % Copy the file
    disp('copying anatomical to reg folder!');
    copyfile(source, destination);


end 