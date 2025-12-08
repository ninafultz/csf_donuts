function [ADC_all_phases, FA_all_phases] = DTIphases_to_niftis(projPath, subject_code, ...
    subjOriginalData, physio);

% goal: convert DTI maps to niftis

subjPath = [projPath, subject_code, '\'];
%% Paths
regDir         = fullfile(subjPath, 'reoriented');
adc            = fullfile(subjOriginalData);
anatFolder     = fullfile(subjPath, 'anat');  % anat folder path
binFolder      = fullfile(subjPath, 'physio_binning');  % anat folder path

mkdir(binFolder);
%% 

        % Target file path
        echo1File = fullfile(regDir, 'B0_from_mhd.nii');

        % Check if the file exists
        fileExists = ~isempty(dir(echo1File));  % Use 'dir' to handle wildcards


        % Find the source file in the anat folder
         sourceFiles = dir(fullfile(regDir, 'B0_from_mhd.nii'));

            
                    % Conditional check
        % if strcmp(subject_code, '20191022_Reconstruction')
        %     echo1File = fullfile(regDir, 'B0_from_mhd.nii');
        %     sourceFiles = dir(fullfile(anatFolder, 'B0_from_mhd.nii'));
        % end
        
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
mat_files = dir(fullfile(adc, 'DTIresult_phase*.mat'));  % List all .mat files in the t2_maps folder
ADC_all_phases = [];
for i = 1:length(mat_files)
    % Load the current T2 map .mat file
    mat_file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    loaded_data = load(mat_file_path);
    
    % Get the field name dynamically (since the variable name may vary)
    var_name = fieldnames(loaded_data);  % Get the name of the variable (e.g., 'T2_map_CSF')
    ADC_map = loaded_data.ADC;  % Access the T2 map data
    ADC_map_avg = ADC_map; 
    ADC_map_avg = flipud(ADC_map_avg);
    ADC_map_avg = permute(ADC_map_avg,[3 2 1]);  % Flips the first dimension (top-to-bottom)
    ADC_map_avg = flip(ADC_map_avg, 1);
    
    b0 = niftiread([fullfile(regDir,'B0_from_mhd.nii')]);


    %% doing a size check 
    % 
    % b0 size is ...
    % CSF_mobility size is ...
fprintf('reference b0 size: [%d %d %d]\n', size(b0))
fprintf('csf mobility size: [%d %d %d]\n', size(ADC_map_avg))

clear nii_data_zeros;
targetSize = [422, 556, 450];

x = size(ADC_map_avg);
% Check size
if ~isequal(size(ADC_map_avg), targetSize) && x(3) == 430
    fprintf('Zero padding ADC_map_avg along z-dimension...\n')

            nii_data_zeros = ADC_map_avg;
            numPad = 20;
            nii_data_zeros = cat(3, zeros(size(nii_data_zeros,1), ...
            size(nii_data_zeros,2), numPad), nii_data_zeros);
            
            ADC_map_avg_withzeros = nii_data_zeros;
            ADC_map_avg_b0 = ADC_map_avg_withzeros .* (b0>50);
            % nii_data = mat2gray(min(max(nii_data_zeros,0),0.05)/0.05);
            % rgb_vol = repmat(nii_data,[1 1 1 3]);
            % rgb_vol(:,:,:,1) = rgb_vol(:,:,:,1) + 0.5*double(roi_pvsas);
            % rgb_vol(:,:,:,2) = rgb_vol(:,:,:,2) + 0.5*double(roi_sas);
            % rgb_vol(rgb_vol > 1) = 1;
            % figure('Name', sprintf('%s - %s - ROI %s', subject_code, physio, roiName));
            % imshow3Dfull(rgb_vol);
            % title(sprintf('%s - %s - ROI %s (0-0.05 window)', subject_code, physio, roiName));   
    else
                ADC_map_avg_b0 = ADC_map_avg .* (b0>50);

end

    % Update the NIfTI header information for this FA map
    niftiInfo.ImageSize = size(ADC_map_avg_b0);
    niftiInfo.Datatype  = class(ADC_map_avg_b0);  % Match the datatype to the FA map
    
    % % Define the output NIfTI file name based on the input .mat file name
    [~, base_name, ~] = fileparts(mat_files(i).name); % Get the base name without extension
    output_nii_file = fullfile(binFolder, [physio '_' base_name '_ADC_thr50.nii']); % Define the output .nii file path
    % 
    % Save the T2 map as a NIfTI file
    niftiwrite(ADC_map_avg_b0, output_nii_file, niftiInfo);
    ADC_all_phases = [ADC_all_phases ADC_map_avg_b0];


    %%
end


%%

%% Loop through all T2 map files in the kspace folder
mat_files = dir(fullfile(adc, 'DTIresult_phase*.mat'));  % List all .mat files in the t2_maps folder
FA_all_phases = [];

clear nii_data_zeros;
targetSize = [422, 556, 450];

x = size(ADC_map_avg);
% Check size

for i = 1:length(mat_files)
    % Load the current T2 map .mat file
    mat_file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    loaded_data = load(mat_file_path);
    
    % Get the field name dynamically (since the variable name may vary)
    var_name = fieldnames(loaded_data);  % Get the name of the variable (e.g., 'T2_map_CSF')
    ADC_map = loaded_data.FA;  % Access the T2 map data
    ADC_map_avg = ADC_map; 
    ADC_map_avg = flipud(ADC_map_avg);
    ADC_map_avg = permute(ADC_map_avg,[3 2 1]);  % Flips the first dimension (top-to-bottom)
    ADC_map_avg = flip(ADC_map_avg, 1);
   b0 = niftiread([fullfile(regDir,'B0_from_mhd.nii')]);

 

if ~isequal(size(ADC_map_avg), targetSize) && x(3) == 430
    fprintf('Zero padding FA_map_avg along z-dimension...\n')

            nii_data_zeros = ADC_map_avg;
            numPad = 20;
            nii_data_zeros = cat(3, zeros(size(nii_data_zeros,1), ...
            size(nii_data_zeros,2), numPad), nii_data_zeros);
            
            ADC_map_avg_withzeros = nii_data_zeros;
            ADC_map_avg_b0 = ADC_map_avg_withzeros .* (b0>50);
            % nii_data = mat2gray(min(max(nii_data_zeros,0),0.05)/0.05);
            % rgb_vol = repmat(nii_data,[1 1 1 3]);
            % rgb_vol(:,:,:,1) = rgb_vol(:,:,:,1) + 0.5*double(roi_pvsas);
            % rgb_vol(:,:,:,2) = rgb_vol(:,:,:,2) + 0.5*double(roi_sas);
            % rgb_vol(rgb_vol > 1) = 1;
            % figure('Name', sprintf('%s - %s - ROI %s', subject_code, physio, roiName));
            % imshow3Dfull(rgb_vol);
            % title(sprintf('%s - %s - ROI %s (0-0.05 window)', subject_code, physio, roiName));   
    else
                ADC_map_avg_b0 = ADC_map_avg .* (b0>50);

end

    % Update the NIfTI header information for this FA map
    niftiInfo.ImageSize = size(ADC_map_avg_b0);
    niftiInfo.Datatype  = class(ADC_map_avg_b0);  % Match the datatype to the FA map

  % % Define the output NIfTI file name based on the input .mat file name
    [~, base_name, ~] = fileparts(mat_files(i).name); % Get the base name without extension
    output_nii_file = fullfile(binFolder, [physio '_' base_name '_FA_thr50.nii']); % Define the output .nii file path

    % Save the T2 map as a NIfTI file
    niftiwrite(ADC_map_avg_b0, output_nii_file, niftiInfo);
    FA_all_phases = [FA_all_phases ADC_map_avg_b0];


    %%
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

 


end

