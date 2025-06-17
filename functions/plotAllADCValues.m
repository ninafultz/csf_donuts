function plotConcentricCircles(project_directory, project_name, subject_list, roi_patterns, voxel_size)

% Initialize structure to store data
roi_data = struct();
for roi_name = roi_patterns
    roi_data.(roi_name{1}).ADC = {}; % Cell array for variable-length ADC data
end

% Process each subject
for subj = 1:length(subject_list)
    subject_code = subject_list(subj).name;
    subjPath = fullfile(project_directory, project_name, subject_code);
    ROIs_dir = fullfile(subjPath, 'ROIs');
    reoriented_dir = fullfile(subjPath, 'reoriented');

    % Load ADC image
    ADC = niftiread(fullfile(reoriented_dir, 'masked_b0_ADC_properorientation_thr75.0000.nii'));
    ADC_size = size(ADC);
    
    % Process each ROI
    for roi_name = roi_patterns
        roi_files = dir(fullfile(ROIs_dir, strcat('*', roi_name{1}, '*.nii*')));
        if isempty(roi_files)
            warning(['No ROI files found for pattern: ', roi_name{1}]);
            continue;
        end
        
        for i = 1:length(roi_files)
            ROI_path = fullfile(roi_files(i).folder, roi_files(i).name);
            ROI = niftiread(ROI_path);
            ROI_resampled = imresize3(ROI, ADC_size, 'nearest') > 0;

            % Extract all ADC values (including zeros)
            adcValues = ADC(ROI_resampled);
            roi_data.(roi_name{1}).ADC{end+1} = adcValues;
        end
    end
end

% Create separate plots for each ROI
for idx = 1:length(roi_patterns)
    roi_name = roi_patterns{idx};
    if isempty(roi_data.(roi_name).ADC)
        continue;
    end

    % Create a new figure for the current ROI
    figure('Name', ['ADC Values for ROI: ', roi_name], 'NumberTitle', 'off');
    set(gcf, 'Color', 'w');  % Set the figure background color to white
    hold on;

    % Loop through subjects for the current ROI
    for subject_idx = 1:length(roi_data.(roi_name).ADC)
        adc_values = roi_data.(roi_name).ADC{subject_idx};
        x_mm = (1:length(adc_values)) * voxel_size; % x-axis in mm

        % Plot ADC values for this subject
        plot(x_mm, adc_values, '-o', 'DisplayName', ['Subject ', num2str(subject_idx)]);
    end

    % Add labels, title, and legend for this ROI
    xlabel('Distance (mm)');
    ylabel('ADC Intensity');
    title(['ADC Values for ROI: ', roi_name]);
    grid on;
    legend('show', 'Location', 'best');
    hold off;
end
end
