function [ADC_map_avg, FA_map_avg] = ADCandFAmaps_to_niftis(subjPath, subject_code);

% goal: convert adc and fa maps to niftis
% register t2 maps to the b0 


%% Paths
regDir         = fullfile(subjPath, 'reg');
fa             = fullfile(subjPath, 'fa');
adc            = fullfile(subjPath, 'adc');
anatFolder     = fullfile(subjPath, 'anat');  % anat folder path
%% 

        % Target file path
        echo1File = fullfile(regDir, 'B0_from_mhd.nii');

        % Check if the file exists
        fileExists = ~isempty(dir(echo1File));  % Use 'dir' to handle wildcards


        % Find the source file in the anat folder
         sourceFiles = dir(fullfile(anatFolder, 'B0_from_mhd.nii'));

            
                    % Conditional check
%         if strcmp(subject_code, '20191022_Reconstruction')
%             echo1File = fullfile(regDir, 'B0_from_mhd.nii');
%             sourceFiles = dir(fullfile(anatFolder, 'B0_from_mhd.nii'));
%         end
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
mat_files = dir(fullfile(adc, '*.mat'));  % List all .mat files in the t2_maps folder

for i = 1:length(mat_files)
    % Load the current T2 map .mat file
    mat_file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    loaded_data = load(mat_file_path);
    
    % Get the field name dynamically (since the variable name may vary)
    var_name = fieldnames(loaded_data);  % Get the name of the variable (e.g., 'T2_map_CSF')
    ADC_map = loaded_data.ADC_cardiac;  % Access the T2 map data
    ADC_map_avg = mean(ADC_map, 4); % Compute the mean along the 4th dimension
    ADC_map_avg = flipud(ADC_map_avg);
    ADC_map_avg = permute(ADC_map_avg,[3 2 1]);  % Flips the first dimension (top-to-bottom)
    ADC_map_avg = flip(ADC_map_avg, 1);
    

    % Update the NIfTI header information for this FA map
    niftiInfo.ImageSize = size(ADC_map_avg);
    niftiInfo.Datatype  = class(ADC_map_avg);  % Match the datatype to the FA map
    
    % % Define the output NIfTI file name based on the input .mat file name
    [~, base_name, ~] = fileparts(mat_files(i).name); % Get the base name without extension
    output_nii_file = fullfile(adc, [base_name '.nii']); % Define the output .nii file path
    % 
    % Save the T2 map as a NIfTI file
    niftiwrite(ADC_map_avg, output_nii_file, niftiInfo);

end

%% 

% target_image = niftiread(output_nii_file);
% output_nii_file_ADC = niftiread(output_nii_file_ADC);
% % 
% % % 
% figure;
% subplot(1,2,1);
% imshow(imageData_avg(:, :, 150), []);  % Display the target image slice
% hold on;
% subplot(1,2,2);
% imshow(ADC_map_avg(:,:,150), [0 0.07]);  % Overlay with transparency
% hold off;


% figure;
% % 
% % Display the target image slice
% subplot(1, 2, 1);
% imshow(imageData_avg_single(:, :, 150), []);
% title('Target Image Slice');
% xlabel('X-axis'); ylabel('Y-axis');
% 
% % Display the ADC map slice with specified intensity range
% subplot(1, 2, 2);
% imshow(ADC_map_avg(:, :, 150), [0 0.07]);
% title('ADC Map Slice');

%%
mat_files = dir(fullfile(fa, '*.mat'));  % List all .mat files in the FA folder

for i = 1:length(mat_files)
    % Load the current FA .mat file
    mat_file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    loaded_data = load(mat_file_path);
    
    % Get the field name dynamically (since the variable name may vary)
    var_name = fieldnames(loaded_data);  % Get the name of the variable (e.g., 'T2_map_CSF')
    FA_map = loaded_data.FA_cardiac;  % Access the FA map data
    FA_map_avg = mean(FA_map, 4);
    FA_map_avg = flipud(FA_map_avg);
    FA_map_avg = permute(FA_map_avg,[3 2 1]);  % Flips the first dimension (top-to-bottom)
    FA_map_avg = flip(FA_map_avg, 1);
    
    % Update the NIfTI header information for this FA map
    niftiInfo.ImageSize = size(FA_map_avg);
    niftiInfo.Datatype = class(FA_map_avg);  % Match the datatype to the FA map
    
    % Define the output NIfTI file name based on the input .mat file name
    [~, base_name, ~] = fileparts(mat_files(i).name);  % Get the base name without extension
    output_nii_file = fullfile(fa, [base_name '.nii']);  % Define the output .nii file path
    
    % Save the T2 map as a NIfTI file
    niftiwrite(FA_map_avg, output_nii_file, niftiInfo);
    
    fprintf('Converted %s to %s\n', mat_files(i).name, output_nii_file);  % Display conversion status
    
  
    
end

%% 

addpath('/exports/gorter-hpc/users/ninafultz/scripts/spm12')

end
