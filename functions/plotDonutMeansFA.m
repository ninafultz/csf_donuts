function plotADCandB0Values(project_directory, project_name, subject_list, roi_patterns, voxel_size)
%% 
    % Process the first subject only
    subject_code = subject_list(1).name;
    subjPath = fullfile(project_directory, project_name, subject_code);
    ROIs_dir = fullfile(subjPath, 'ROIs');
    reoriented_dir = fullfile(subjPath, 'reoriented');

    % Load the images
    ADC = niftiread(fullfile(reoriented_dir, 'maskedFA_properorientation_thr75.0000.nii'));
    b0 = niftiread(fullfile(reoriented_dir, 'B0_properOrientation_thr75.0000.nii'));
    ADC_size = size(ADC);

    % Initialize figure for plotting
    figure('Name', 'FA and B0 Profiles', 'NumberTitle', 'off');
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

            % Extract ADC and B0 values within the ROI
            adcValues = ADC(ROI_resampled);
            b0Values = b0(ROI_resampled);


            zeroIndices = find(adcValues == 0);

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



% Identify indices of zeros
zeroIndices = find(adcValues == 0);

% Find the longest sequence of zeros in the middle
diffs = diff(zeroIndices);
splitPoints = find(diffs > 1);

if ~isempty(splitPoints)
    startIdx = zeroIndices(splitPoints(1) + 1); % Start of middle zero block
    endIdx = zeroIndices(splitPoints(end));     % End of middle zero block
else
    startIdx = zeroIndices(1);
    endIdx = zeroIndices(end);
end

% Find indices just outside the middle zero block
indexAbove = startIdx - 1;
indexBelow = endIdx + 1;

% Ensure indices are within bounds
if indexAbove < 1
    indexAbove = NaN;
end
if indexBelow > length(adcValues)
    indexBelow = NaN;
end

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




yyaxis right
fill([x_mm', fliplr(x_mm')], [double(b0Values)', zeros(1, length(b0Values))], ...
     [0.5, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', ['B0 - ', roi_name{1}]);
ylabel('B0 Values'); % Label for the right y-axis

            % Plot ADC values
            yyaxis left
            plot(x_mm, adcValues, '-o', 'Color', [0.7, 0.7, 0.7], ...
                 'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                 'MarkerSize', 4, 'DisplayName', ['ADC - ', roi_name{1}]);
            ylabel('FA Values'); % Label for the left y-axis
            ylim([0 1])

            % Add title and legend
            xlabel('Distance from Middle Zeros (mm)');
            title(['FA and B0 Profile: ', roi_name{1}]);
            xlim([min(x_mm), max(x_mm)]);

        end
    end

    % Finalize plot appearance
    legend('show', 'Location', 'best');
    set(gcf, 'Renderer', 'painters');  % High-resolution rendering
    grid on;
    hold off;
end

