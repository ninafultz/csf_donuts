function plotDonutMeans(project_directory, project_name, subject_list, roi_patterns, voxel_size);
roi_data = struct();

for roi_name = roi_patterns
    roi_data.(roi_name{1}).ADC = {}; % Cell array for variable-length ADC data
    roi_data.(roi_name{1}).FA = {};  % Cell array for variable-length FA data
end

num_rois = length(roi_patterns);
rows = num_rois; % One row per ROI

% Process each subject
for subj = 1:length(subject_list)
    subject_code = subject_list(subj).name;
    subjPath = fullfile(project_directory, project_name, subject_code);
    ROIs_dir = fullfile(subjPath, 'ROIs');
    reoriented_dir = fullfile(subjPath, 'reoriented');

     % Load the images
    ADC = niftiread(fullfile(reoriented_dir, 'masked_b0_ADC_properorientation_thr75.0000.nii'));
    FA = niftiread(fullfile(reoriented_dir, 'maskedFA_properorientation_thr75.0000.nii'));
    ADC_size = size(ADC);
        
    % Load and process ROIs
    for roi_name = roi_patterns
        roi_files = dir(fullfile(ROIs_dir, strcat('*', roi_name{1}, '*.nii*')));
        if isempty(roi_files)
            warning(['No ROI files found for pattern: ', subject_code, roi_name{1}]);
            continue;
        end
        
        for i = 1:length(roi_files)
            ROI_path = fullfile(roi_files(i).folder, roi_files(i).name);
            ROI = niftiread(ROI_path);
            ROI_resampled = imresize3(ROI, ADC_size, 'nearest') > 0;

            % Extract values within the ROI
            adcValues = ADC(ROI_resampled);
            faValues = FA(ROI_resampled);

                        % Store data in cell arrays
            roi_data.(roi_name{1}).ADC{end+1} = adcValues;
            roi_data.(roi_name{1}).FA{end+1} = faValues;
        end
    end
end
%% 
 % Initialize a figure for the plot
figure('Name', 'Cross-Sectional Patterns', 'NumberTitle', 'off');
set(gcf, 'Color', 'w');  % Set the figure background color to white
set(gcf, 'Renderer', 'painters');  % Set the renderer to 'painters' for high resolution
hold on;


% Loop through each ROI and plot
for idx = 1:num_rois
    roi_name = roi_patterns{idx};
    if isempty(roi_data.(roi_name).ADC)
        continue;
    end

    % Create a new figure for the current ROI
    figure('Name', ['ADC Pattern: ', roi_name], 'NumberTitle', 'off');
    hold on;

    % Initialize a cell to store all the ADC values across subjects
    all_x_mm = [];
    all_adc_values = [];

    % Loop through subjects within the ROI
    for subject_idx = 1:length(roi_data.(roi_name).ADC)
        adc_values = roi_data.(roi_name).ADC{subject_idx};

        % Find zero indices
        zero_indices = find(adc_values == 0);

        % Determine the zero voxel closest to the center
        center_idx = floor(length(adc_values) / 2) + 1;
        if isempty(zero_indices)
            warning(['No zeros found for ROI: ', roi_name, ', Subject: ', num2str(subject_idx)]);
            continue; % Skip if no zero found
        end
        [~, closest_zero_idx] = min(abs(zero_indices - center_idx));

        % Retain only the central zero
        keep_indices = true(size(adc_values));
        keep_indices(zero_indices(zero_indices ~= zero_indices(closest_zero_idx))) = false;

        % Apply the mask to filter the ADC values
        filtered_adc_values = adc_values(keep_indices);

        % Recalculate x_mm positions relative to the central zero
        % find goes from left to right 
        filtered_indices = find(keep_indices);
        zero_position = find(filtered_indices == zero_indices(closest_zero_idx));
        x_mm = ((1:length(filtered_adc_values)) - zero_position) * voxel_size;

        % Plot the raw data with a light grey color and slight opacity
        plot(x_mm, filtered_adc_values, '-o', 'Color', [0.7, 0.7, 0.7], 'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], 'MarkerEdgeColor', [0.7, 0.7, 0.7], 'MarkerSize', 4, 'DisplayName', ['Subject ', num2str(subject_idx)]);
        
        % Store all the ADC values and corresponding x_mm values across subjects
        all_adc_values = [all_adc_values; filtered_adc_values(:)];
        all_x_mm = [all_x_mm, x_mm]; % Collect x_mm positions
    end

    % Sort the x_mm values and average the ADC values for each voxel position
    [unique_x_mm, ia, ~] = unique(all_x_mm); % Find unique x_mm positions and their indices
    mean_adc = arrayfun(@(x) mean(all_adc_values(all_x_mm == x), 'omitnan'), unique_x_mm); % Average ADC values at each x_mm position

    % Plot the mean ADC values with a solid line
    plot(unique_x_mm, mean_adc, '-o', 'LineWidth', 2, 'DisplayName', 'Mean ADC', 'Color', 'b');

    % Add labels and title
    xlabel('Distance from Zero (mm)');
    ylabel('ADC Intensity');
    title(['ADC Cross-Sectional Pattern: ', roi_name]);
    grid on;
    legend('show', 'Location', 'best');
    hold off;

    % Make sure the figure is visible
    drawnow;
end

end

