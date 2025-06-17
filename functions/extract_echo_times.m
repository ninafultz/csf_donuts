function echo_times = extract_echo_times(directory_path, common_prefix)
 
%% 

    % Find all NIfTI files matching the pattern
    nifti_files = dir(fullfile(directory_path, [common_prefix '_e*_ph.nii']));
    nifti_files = {nifti_files.name};  % Extract file names into a cell array

    % Initialize array to store echo times
    echo_times = zeros(1, numel(nifti_files));

    % Loop through each NIfTI file
    for idx = 1:numel(nifti_files)
        nifti_file = fullfile(directory_path, nifti_files{idx});

        % Load NIfTI file
        nii_info = niftiinfo(nifti_file);
        nii_data = niftiread(nii_info);

        % Save the masked NIfTI file
        [~, nifti_base, ~] = fileparts(nifti_files{idx});

        % Remove both .nii and .nii.gz extensions from file name
        nifti_base = strrep(nifti_base, '.nii', '');
        nifti_base = strrep(nifti_base, '.gz', '');

        % Construct JSON file name based on NIfTI file name
        json_file = fullfile(directory_path, [nifti_base '.json']);

        % Read JSON file
        json_data = jsondecode(fileread(json_file));

        % Extract echo time (adjust field name as per your JSON structure)
        echo_times(idx) = json_data.EchoTime * 1000;  % Replace 'EchoTime' with your actual field name
    end

    % Print extracted echo times
    disp('Echo Times:');
    disp(echo_times);
end