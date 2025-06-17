function t1s_to_niftis(subjPath);

% goal: convert adc and fa maps to niftis
% register t2 maps to the b0 


%% Paths
regDir         = fullfile(subjPath, 'reg');
anatFolder     = fullfile(subjPath, 'anat');  % anat folder path

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
mat_files = dir(fullfile(adc, '*.mat'));  % List all .mat files in the t2_maps folder

for i = 1:length(mat_files)
    % Load the current T2 map .mat file
    mat_file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    loaded_data = load(mat_file_path);
    
    % Get the field name dynamically (since the variable name may vary)
    var_name = fieldnames(loaded_data);  % Get the name of the variable (e.g., 'T2_map_CSF')
    ADC_map = loaded_data.ADC_cardiac;  % Access the T2 map data
    ADC_map_avg = mean(ADC_map, 4); % Compute the mean along the 4th dimension

    
    % Update the NIfTI header information for this T2 map
    niftiInfo.ImageSize = size(ADC_map_avg);
    niftiInfo.Datatype = class(ADC_map_avg);  % Match the datatype to the T2 map
    
    % Define the output NIfTI file name based on the input .mat file name
    [~, base_name, ~] = fileparts(mat_files(i).name);  % Get the base name without extension
    output_nii_file = fullfile(adc, [base_name '.nii']);  % Define the output .nii file path
    
    % Save the T2 map as a NIfTI file
    niftiwrite(ADC_map_avg, output_nii_file, niftiInfo);
    
    fprintf('Converted %s to %s\n', mat_files(i).name, output_nii_file);  % Display conversion status
end

%%
mat_files = dir(fullfile(fa, '*.mat'));  % List all .mat files in the FA folder

for i = 1:length(mat_files)
    % Load the current FA .mat file
    mat_file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    loaded_data = load(mat_file_path);
    
    % Get the field name dynamically (since the variable name may vary)
    var_name = fieldnames(loaded_data);  % Get the name of the variable (e.g., 'T2_map_CSF')
    FA_map = loaded_data.FA_cardiac;  % Access the FA map data
    
    % Update the NIfTI header information for this FA map
    niftiInfo.ImageSize = size(FA_map);
    niftiInfo.Datatype = class(FA_map);  % Match the datatype to the FA map
    
    % Define the output NIfTI file name based on the input .mat file name
    [~, base_name, ~] = fileparts(mat_files(i).name);  % Get the base name without extension
    output_nii_file = fullfile(fa, [base_name '.nii']);  % Define the output .nii file path
    
    % Save the T2 map as a NIfTI file
    niftiwrite(FA_map, output_nii_file, niftiInfo);
    
    fprintf('Converted %s to %s\n', mat_files(i).name, output_nii_file);  % Display conversion status
end

%% 

addpath('/exports/gorter-hpc/users/ninafultz/scripts/spm12')

end
