function B0_to_niftis(subjPath, imageData);

% goal: convert adc and fa maps to niftis
% register t2 maps to the b0 


%% Paths
regDir         = fullfile(subjPath, 'reg');
anatFolder     = fullfile(subjPath, 'anat');  % anat folder path
mhd            = fullfile(subjPath, 'mhd');

% Target file path
echo1File = fullfile(regDir, '*_properOrientation.nii');

% Check if the file exists
fileExists = ~isempty(dir(echo1File));  % Use 'dir' to handle wildcards


    % Find the source file in the anat folder
        sourceFiles = dir(fullfile(anatFolder, '*_properOrientation.nii'));
            % Assume only one match for the wildcard (update if multiple files need handling)
        sourceFile = fullfile(sourceFiles(1).folder, sourceFiles(1).name);
        
        % Define target file path in regDir (preserve the filename)
        [~, filename, ext] = fileparts(sourceFile);
        targetFile = fullfile(regDir, [filename, ext]);
               
        niftiInfo = niftiinfo(targetFile);
        disp(niftiInfo);
    if ~fileExists
        if ~isempty(sourceFiles)

        % Copy the file
            copyfile(sourceFile, targetFile);
            fprintf('File copied to %s\n', targetFile);

        else
            error('No matching files found in %s\n', anatFolder);
        end
else
    fprintf('File already exists: %s\n', echo1File);
end


%% Loop through all T2 map files in the kspace folder

    imageData_avg = mean(imageData, 4); % Compute the mean along the 4th dimension
%     imageData_avg = flipud(imageData_avg);
%     imageData_avg = permute(imageData_avg,[3 2 1]);  % Flips the first dimension (top-to-bottom)
%     imageData_avg = flip(imageData_avg, 1);
    imageData_avg_single = single(imageData_avg);
    
    % Get the size of the target file from the NIfTI header

    niftiInfo.ImageSize = size(imageData_avg_single);
    niftiInfo.Datatype  = class(imageData_avg_single);  % Match the datatype to the FA map
    
    % % Define the output NIfTI file name based on the input .mat file name
    output_nii_file = fullfile(mhd, ['B0_properOrientation.nii']); % Define the output .nii file path
    % 
    % Save the T2 map as a NIfTI file
    niftiwrite(imageData_avg_single, output_nii_file, niftiInfo);

end