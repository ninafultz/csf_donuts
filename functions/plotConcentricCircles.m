function plotConcentricCircles(project_directory, project_name, subject_list, roi_patterns, voxel_size)
    %% Parameters
    num_layers = 20; % Number of concentric circles
    layer_thickness = 0.45; % Thickness of each layer in voxel units

    % Process each subject
    for subj = 1:length(subject_list)
        subject_code = subject_list(subj).name;
        subjPath = fullfile(project_directory, project_name, subject_code);
        reoriented_dir = fullfile(subjPath, 'reoriented');
        ROIs_dir = fullfile(subjPath, 'ROIs');

        % Load ADC map
        ADC = niftiread(fullfile(reoriented_dir, 'masked_b0_ADC_properorientation_thr75.0000.nii'));
        ADC_size = size(ADC);

        % Load ROI
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

                % Calculate distance map
                dist_map = bwdist(ROI_resampled);

                % Initialize a 4D matrix to store the concentric layers
                concentric_adc = zeros([size(ADC), num_layers]);

                % Generate concentric layers
                for layer = 1:num_layers
                    inner_radius = (layer - 1) * layer_thickness;
                    outer_radius = layer * layer_thickness;

                    % Mask for current layer
                    concentric_layer = (dist_map > inner_radius) & (dist_map <= outer_radius);

                    % Apply the mask to the ADC map
                    concentric_adc(:,:,:,layer) = ADC .* concentric_layer;
                end

                %% Visualization
                figure;
                for layer = 1:1
                    % Extract the ADC map for the current layer
                    layer_data = concentric_adc(:,:,:,5);

                    % Maximum intensity projection for visualization
                    max_projection = max(layer_data, [], 3);

                    % Plot the maximum projection
                    subplot(1, 1, 1); % Adjust subplot grid based on num_layers
                    imagesc(layer_data);
                    axis equal tight;
                    colormap('parula');
                    colorbar;
                    title(['Layer ', num2str(layer)]);
                end
               

                % Optional: Interactive 3D visualization
%                 figure;
%                 imshow3Dfull(concentric_adc(:,:,:,end), [0 0.05]);
            end
        end
    end
end
