function plotADCandB0Values(project_directory, project_name, subject_list, roi_patterns, voxel_size)
    %% Process the first subject only
    subject_code = subject_list(1).name;
    subjPath = fullfile(project_directory, project_name, subject_code);
    ROIs_dir = fullfile(subjPath, 'ROIs');
    reoriented_dir = fullfile(subjPath, 'reoriented');

    % Load the images
    ADC = niftiread(fullfile(reoriented_dir, 'masked_b0_ADC_mhd_thr100.0000.nii'));
    b0 = niftiread(fullfile(reoriented_dir, 'B0_from_mhd.nii'));

    ADC_size = size(ADC);

    % Initialize figure for plotting
    figure('Name', 'ADC and B0 Profiles', 'NumberTitle', 'off');
    set(gcf, 'Color', 'w');  
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

            % Compute the centerline
            ROI_centerline = bwmorph(ROI_resampled, 'skel', Inf);  
            [y_idx, x_idx] = find(ROI_centerline); 

            % Sort indices along the path
            [sorted_idx, sort_order] = sortrows([x_idx, y_idx]); 
            x_idx = sorted_idx(:, 1);
            y_idx = sorted_idx(:, 2);

            % Compute distances along the centerline
            distances = cumsum([0; sqrt(diff(x_idx).^2 + diff(y_idx).^2)]) * voxel_size;

            % Extract ADC and B0 values along the centerline
            adcValues = ADC(sub2ind(size(ADC), y_idx, x_idx));
            b0Values = b0(sub2ind(size(b0), y_idx, x_idx));

            % Flip x-axis values for proper orientation
            distances_flipped = -distances;

            % Plot B0 values (right y-axis)
            yyaxis right
            fill([distances_flipped', fliplr(distances_flipped')], ...
                 [double(b0Values)', zeros(1, length(b0Values))], ...
                 [0.5, 0.8, 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
                 'DisplayName', ['B0 - ', roi_name{1}]);
            ylabel('B0 Values');

            % Plot ADC values (left y-axis)
            yyaxis left
            plot(distances_flipped, adcValues, '-o', 'Color', [0.7, 0.7, 0.7], ...
                 'LineWidth', 1, 'MarkerFaceColor', [0.7, 0.7, 0.7], ...
                 'MarkerSize', 4, 'DisplayName', ['ADC - ', roi_name{1}]);
            ylabel('ADC Values'); 
            ylim([0 0.11])

            % Title and labels
            xlabel('Distance along ROI Centerline (mm)');
            title(['ADC and B0 Profile: ', roi_name{1}]);
            xlim([min(distances_flipped), max(distances_flipped)]);
        end
    end

    % Finalize plot appearance
    legend('show', 'Location', 'best');
    set(gcf, 'Renderer', 'painters');  
    grid on;
    hold off;
end