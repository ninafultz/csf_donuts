function plotADCandB0Values(project_directory, project_name, subject_list, roi_patterns, voxel_size)
%% 
    % Process the first subject only
    subject_code = subject_list(1).name;
    subjPath = fullfile(project_directory, project_name, subject_code);
    ROIs_dir = fullfile(subjPath, 'ROIs');
    reoriented_dir = fullfile(subjPath, 'reoriented');

    % Load the images
    ADC = niftiread(fullfile(reoriented_dir, 'masked_b0_ADC_mhd_thr100.0000.nii'));
   % b0 = niftiread(fullfile(reoriented_dir, 'B0_properOrientation_thr75.0000.nii'));
    b0 = niftiread(fullfile(reoriented_dir, 'B0_from_mhd.nii'));

    
    ADC_size = size(ADC);

    % Initialize figure for plotting
    figure('Name', 'ADC and B0 Profiles', 'NumberTitle', 'off');
    set(gcf, 'Color', 'w');  % Set figure background color to white
    hold on;

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

            
            adcValues = ADC(ROI_resampled);
            b0Values = b0(ROI_resampled);
            
            
          % If the ROI is 'ACEPOINT', consider any ADC value less ...
           % than 0.003 as zero;
           % otherwise, treat only exact zeros as zero.
            if strcmp(roi_files(i).name, 'ACEPOINT.nii')
                zeroIndices = find(adcValues < 0.006);
            else
                zeroIndices = find(adcValues == 0);
            end
           % zeroIndices = find(adcValues <= 0.005); % just for acepoint

            % Find the longest sequence of zeros
            diffs = diff(zeroIndices);
            splitPoints = find(diffs > 1); % Gaps indicate separate zero groups

            if ~isempty(splitPoints)
                startIdx = zeroIndices(splitPoints(1) + 1); % Start of middle zero block
                endIdx = zeroIndices(splitPoints(end));     % End of middle zero block
            else
                startIdx = zeroIndices(1);
                endIdx = zeroIndices(end);
            end

            % Find the indices just outside the middle zero block
            indexAbove = startIdx - 1;
            indexBelow = endIdx + 1;

            % Ensure indices are within bounds
            if indexAbove < 1
                indexAbove = NaN;
            end
            if indexBelow > length(adcValues)
                indexBelow = NaN;
            end

fprintf('Index above middle zeros: %d\n', indexAbove);
fprintf('Index below middle zeros: %d\n', indexBelow);
%% 


%

% Use indexBelow as reference if available, otherwise indexAbove
if ~isnan(indexBelow)
    referenceIndex = indexBelow;
elseif ~isnan(indexAbove)
    referenceIndex = indexAbove;
else
    error('No valid reference index found.');
end

%% 

% Automatically assign distances in mm
x_mm = zeros(size(adcValues)); % Initialize


% Assign values above the middle zero block
for i = indexAbove:-1:1
    x_mm(i) = x_mm(i+1) - voxel_size;
end

% Assign values below the middle zero block
for i = indexBelow:length(adcValues)
    x_mm(i) = x_mm(i-1) + voxel_size;
end

% Display the new table
resultTable = table(adcValues, x_mm, 'VariableNames', {'adcValues', 'x_mm'});
disp(resultTable);

%% 

% 
% % Flip the x-axis values
% x_mm_flipped = -x_mm;
% 
% yyaxis right
% fill([x_mm_flipped', fliplr(x_mm_flipped')], [double(b0Values)', zeros(1, length(b0Values))], ...
%      [0.5, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', ['B0 - ', roi_name{1}]);
% ylabel('B0 Values'); % Label for the right y-axis
% 
%             % Plot ADC values
%             yyaxis left
%             plot(x_mm_flipped, adcValues, '-o', 'Color', [0.7, 0.7, 0.7], ...
%                  'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
%                  'MarkerSize', 4, 'DisplayName', ['ADC - ', roi_name{1}]);
%             ylabel('ADC Values'); % Label for the left y-axis
%             ylim([0 0.11])
% 
%             % Add title and legend
%             xlabel('Distance from Middle Zeros (mm)');
%             title(['ADC and B0 Profile: ', roi_name{1}]);
%             xlim([min(x_mm_flipped), max(x_mm_flipped)]);

% Flip the x-axis values
x_mm_flipped = -x_mm;

% Identify zero regions
zero_idx = find(adcValues == 0);
if isempty(zero_idx)
    % No zeros, use original data
    x_adjusted = x_mm_flipped;
    y_adjusted = adcValues;
else
    % Find the largest middle cluster of zeros
    diff_idx = [1, diff(zero_idx)];
    split_groups = find(diff_idx > 1); % Points where sequences break
    if isempty(split_groups)
        % All zeros are consecutive, treat the whole as the main cluster
        main_zero_idx = zero_idx;
    else
        % Find the longest zero segment (most likely in the middle)
        segment_lengths = diff([split_groups, length(zero_idx) + 1]);
        [~, max_segment_idx] = max(segment_lengths);
        main_zero_idx = zero_idx(split_groups(max_segment_idx):zero_idx(split_groups(max_segment_idx) + segment_lengths(max_segment_idx) - 1));
    end
    
    % Identify leading and trailing zeros
    leading_zeros = zero_idx(zero_idx < main_zero_idx(1));
    trailing_zeros = zero_idx(zero_idx > main_zero_idx(end));
    
    % Define adjusted x and y
    x_adjusted = x_mm_flipped;
    y_adjusted = adcValues;
    
    % Insert vertical rise just after each zero region
    transition_points = [leading_zeros(end), main_zero_idx(end), trailing_zeros(end)];
    transition_points = transition_points(~isnan(transition_points)); % Remove empty cases
    
    for i = 1:length(transition_points)
        idx = find(x_mm_flipped == x_mm_flipped(transition_points(i)), 1);
        if idx < length(adcValues)
            x_adjusted = [x_adjusted(1:idx), x_adjusted(idx), x_adjusted(idx+1:end)];
            y_adjusted = [y_adjusted(1:idx), 0, y_adjusted(idx+1:end)];
        end
    end
end

% Plot B0 Values (Right Y-Axis)
yyaxis right
fill([x_mm_flipped', fliplr(x_mm_flipped')], [double(b0Values)', zeros(1, length(b0Values))], ...
     [0.5, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', ['B0 - ', roi_name{1}]);
ylabel('B0 Values');

% Plot ADC Values with selective vertical transitions
yyaxis left
plot(x_adjusted, y_adjusted, '-o', 'Color', [0.7, 0.7, 0.7], ...
     'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
     'MarkerSize', 4, 'DisplayName', ['ADC - ', roi_name{1}]);

ylabel('ADC Values');
ylim([0 0.11])

% Add title and legend
xlabel('Distance from Middle Zeros (mm)');
title(['ADC and B0 Profile: ', roi_name{1}]);
xlim([min(x_mm_flipped), max(x_mm_flipped)]);

        end
    end

    % Finalize plot appearance
    legend('show', 'Location', 'best');
    set(gcf, 'Renderer', 'painters');  % High-resolution rendering
    grid on;
    hold off;
    
    % Flip the x-axis values
x_mm_flipped = -x_mm;

end

