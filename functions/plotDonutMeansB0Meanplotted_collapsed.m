function plotADCandB0Values(project_directory, project_name, subject_list, roi_patterns, voxel_size, adc_map);
%% 
% Inputs:
% project_directory
% project_name
% subject_list
% roi_patterns
% voxel_size
% adc_map

%% 

    % Process the first subject only
    subject_code = subject_list(1).name;
    subjPath = fullfile(project_directory, project_name, subject_code);
    ROIs_dir = fullfile(subjPath, 'ROIs');
    reoriented_dir = fullfile(subjPath, 'reoriented');

    % Load the images
    ADC = niftiread(fullfile(reoriented_dir, adc_map));
   % b0 = niftiread(fullfile(reoriented_dir, 'B0_properOrientation_thr75.0000.nii'));
    b0 = niftiread(fullfile(reoriented_dir, 'B0_from_mhd.nii'));
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

            
            adcValues = ADC(ROI_resampled);
            b0Values = b0(ROI_resampled);
            
            
%           % If the ROI is 'ACEPOINT', consider any ADC value less ...
%            % than 0.003 as zero;
%            % otherwise, treat only exact zeros as zero.
%             if strcmp(roi_files(i).name, 'ACEPOINT.nii.gz')
%                 epsilon = 1e-5;  % you can adjust this depending on your needed precision
%                 zeroIndices = find(abs(adcValues - 0.0047) < epsilon);
%                 [closestDiff, closestIdx] = min(abs(adcValues(:) - 0.0047));
%                     zeroIndices = adcValues(closestIdx);
%             else
%                 zeroIndices = find(adcValues == 0);
%             end
%          
%             if ~isempty(splitPoints)
%                 startIdx = zeroIndices(splitPoints(1) + 1); % Start of middle zero block
%                 endIdx = zeroIndices(splitPoints(end));     % End of middle zero block
%             else
%                 startIdx = zeroIndices(1);
%                 endIdx = zeroIndices(end);
%             end
% 
%             % Find the indices just outside the middle zero block
%             indexAbove = startIdx - 1;
%             indexBelow = endIdx + 1;
% 
%             % Ensure indices are within bounds
%             if indexAbove < 1
%                 indexAbove = NaN;
%             end
%             if indexBelow > length(adcValues)
%                 indexBelow = NaN;
%             end
% 
% fprintf('Index above middle zeros: %d\n', indexAbove);
% fprintf('Index below middle zeros: %d\n', indexBelow);


%%

if strcmp(roi_files(i).name, 'ACEPOINT.nii.gz')
    % For ACEPOINT: use 0.0047 as the "middle zero"
    targetValue = 0.0047;
    [closestDiff, closestIdx] = min(abs(adcValues(:) - targetValue));
    
    % Define the middle index and neighbors
    startIdx = closestIdx;           % middle point
    indexAbove = closestIdx - 1;     % just before
    indexBelow = closestIdx + 1;     % just after
    
    % Bounds checking
    if indexAbove < 1
        indexAbove = NaN;
    end
    if indexBelow > numel(adcValues)
        indexBelow = NaN;
    end
else
    % For other ROIs: find exact zeros as before
    zeroIndices = find(adcValues == 0);

    % Handle zero group logic (same as before)
    diffs = diff(zeroIndices);
    splitPoints = find(diffs > 1);

    if ~isempty(splitPoints)
        startIdx = zeroIndices(splitPoints(1) + 1);
        endIdx = zeroIndices(splitPoints(end));
    else
        startIdx = zeroIndices(1);
        endIdx = zeroIndices(end);
    end

    indexAbove = startIdx - 1;
    indexBelow = endIdx + 1;

    if indexAbove < 1
        indexAbove = NaN;
    end
    if indexBelow > length(adcValues)
        indexBelow = NaN;
    end
end

fprintf('Middle index (0.0047): %d\n', startIdx);
fprintf('Index above: %d\n', indexAbove);
fprintf('Index below: %d\n', indexBelow);

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


    
    %% non collapsed zeros plots 
          %Flip the x-axis values
            figure('Name', 'ADC and B0 Profiles Collapsed', 'NumberTitle', 'off');
            set(gcf, 'Color', 'w', 'Renderer', 'Painters');  % Set background color to white
            hold on;
            x_mm_flipped = -x_mm;

            yyaxis right
            fill([x_mm_flipped', fliplr(x_mm_flipped')], [double(b0Values)', zeros(1, length(b0Values))], ...
                 [0.5, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', ['B0 - ', roi_name{1}]);
            ylabel('B0 Values'); % Label for the right y-axis
            ylim([0 600])

            % Plot ADC values
            yyaxis left
            plot(x_mm_flipped, adcValues, '-o', 'Color', [0.7, 0.7, 0.7], ...
                 'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                 'MarkerSize', 4, 'DisplayName', ['ADC - ', roi_name{1}]);
            ylabel('ADC Values'); % Label for the left y-axis
            ylim([0 0.11])


        end
    end

end

