function mhd_to_niftis(subjPath, referenceScan);

% goal: convert adc and fa maps to niftis
% register t2 maps to the b0 


%% Paths
regDir         = fullfile(subjPath, 'reg');
fa             = fullfile(subjPath, 'fa');
adc            = fullfile(subjPath, 'adc');
anatFolder     = fullfile(subjPath, 'anat');  % anat folder path
%% 

% Target file path
echo1File = fullfile(anatFolder, 'B0_properOrientation.nii');

% Check if the file exists
fileExists = ~isempty(dir(echo1File));  % Use 'dir' to handle wildcards


    % Find the source file in the anat folder
        sourceFiles = dir(fullfile(anatFolder, 'B0_properOrientation.nii'));
            % Assume only one match for the wildcard (update if multiple files need handling)
        sourceFile = fullfile(sourceFiles(1).folder, sourceFiles(1).name);
        

    if ~fileExists
        if ~isempty(sourceFiles)
        [~, filename, ext] = fileparts(sourceFile);
        targetFile = fullfile(regDir, [filename, ext]);
        % Copy the file
            copyfile(sourceFile, targetFile);
            fprintf('File copied to %s\n', targetFile);

        else
            error('No matching files found in %s\n', anatFolder);
        end
        
        % Define target file path in regDir (preserve the filename)
        [~, filename, ext] = fileparts(sourceFile);
        targetFile = fullfile(regDir, [filename, ext]);
        niftiInfo = niftiinfo(targetFile);
        disp(niftiInfo);
else
    fprintf('File already exists: %s\n', echo1File);
    % Define target file path in regDir (preserve the filename)
        [~, filename, ext] = fileparts(sourceFile);
        targetFile = fullfile(regDir, [filename, ext]);
        niftiInfo = niftiinfo(targetFile);
        disp(niftiInfo);
end


%% Loop through all T2 map files in the kspace folder

    % Get the field name dynamically (since the variable name may vary)
    ADC_map_avg = flipud(referenceScan);
    ADC_map_avg = permute(ADC_map_avg,[3 2 1]);  % Flips the first dimension (top-to-bottom)
    ADC_map_avg = flip(ADC_map_avg, 1);
    

    % Update the NIfTI header information for this FA map
    niftiInfo.ImageSize = size(ADC_map_avg);
    niftiInfo.Datatype  = class(ADC_map_avg);  % Match the datatype to the FA map
    
    % % Define the output NIfTI file name based on the input .mat file name
    output_nii_file = fullfile(regDir, 'B0_from_mhd.nii'); % Define the output .nii file path
    
    %output_nii_file = fullfile(regDir, 'ADC_properorientation.nii'); % Define the output .nii file path
    
    % Save the T2 map as a NIfTI file
    niftiwrite(ADC_map_avg, output_nii_file, niftiInfo);

end
