function adcValues = plotADCandB0Values(project_directory, project_name, subject_list, roi_patterns, voxel_size)
    %% Load Subject Data
    subject_code = subject_list(1).name;
    subjPath = fullfile(project_directory, project_name, subject_code);
    ROIs_dir = fullfile(subjPath, 'ROIs');
    reoriented_dir = fullfile(subjPath, 'reoriented');

    % Load ADC and B0 images
    ADC = niftiread(fullfile(reoriented_dir, 'masked_b0_ADC_mhd_thr100.0000.nii'));
    b0 = niftiread(fullfile(reoriented_dir, 'B0_from_mhd.nii'));

    ADC_size = size(ADC);

    % Initialize figure
    figure('Name', 'ADC and B0 Profiles', 'NumberTitle', 'off');
    set(gcf, 'Color', 'w');
    hold on;

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

            
            % make anything not in the middle 
           
            % Extract ADC and B0 values
            adcValues = ADC(ROI_resampled);
            b0Values = b0(ROI_resampled);

               
            % Identify the middle zero block
            zeroIndices = find(adcValues == 0);
            if isempty(zeroIndices)
                warning(['No zero values found in ADC for ROI: ', roi_name{1}]);
                continue;
            end

            startIdx = min(zeroIndices);
            endIdx = max(zeroIndices);
            numZeros = endIdx - startIdx + 1;

            % Assign distances with zeros in the middle
            numLeft = startIdx - 1;
            numRight = length(adcValues) - endIdx;

            x_mm = zeros(size(adcValues));
            x_mm(1:numLeft) = -flip((1:numLeft) * voxel_size);
            x_mm(startIdx:endIdx) = linspace(-numZeros/2 * voxel_size, numZeros/2 * voxel_size, numZeros); % Ensure all middle zeros spread symmetrically
            x_mm(endIdx+1:end) = (1:numRight) * voxel_size;


             %% Plot Data
            yyaxis right
            fill([x_mm', fliplr(x_mm')], [double(b0Values)', zeros(1, length(b0Values))], ...
                 [0.5, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', ['B0 - ', roi_name{1}]);
            ylabel('B0 Values');

            yyaxis left
            plot(x_mm, adcValues, '-o', 'Color', [0.7, 0.7, 0.7], ...
                 'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                 'MarkerSize', 4, 'DisplayName', ['ADC - ', roi_name{1}]);
            ylabel('ADC Values');
            ylim([0 0.11]);

            xlabel('Distance from Vessel (mm)');
            title(['ADC and B0 Profile: ', roi_name{1}]);
            %xlim([min(x_mm), max(x_mm)]);
            yyaxis right
            fill([x_mm', fliplr(x_mm')], [double(b0Values)', zeros(1, length(b0Values))], ...
                 [0.5, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', ['B0 - ', roi_name{1}]);
            ylabel('B0 Values');

            yyaxis left
            plot(x_mm, adcValues, '-o', 'Color', [0.7, 0.7, 0.7], ...
                 'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                 'MarkerSize', 4, 'DisplayName', ['ADC - ', roi_name{1}]);
            ylabel('ADC Values');
            ylim([0 0.11]);

            xlabel('Distance from Vessel (mm)');
            title(['ADC and B0 Profile: ', roi_name{1}]);
            %xlim([min(x_mm), max(x_mm)]);
        end
    end

    % Finalize figure
    legend('show', 'Location', 'best');
    set(gcf, 'Renderer', 'painters');
    grid on;
    hold off;
end