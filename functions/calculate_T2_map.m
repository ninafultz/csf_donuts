function [T2_map, S0, goodnessFit] = calculate_T2_map(img_data, echo_times, t2maps_path)
    % Initialize the dimensions
    [x_dim, y_dim, z_dim, num_echoes] = size(img_data);

    % Preallocate the T2_map matrix for each echo
    T2_map = zeros(x_dim, y_dim, z_dim);
    S0 = zeros(x_dim, y_dim, z_dim);
    goodnessFit = zeros(x_dim, y_dim, z_dim);
    %% 
    % Loop through each voxel in the 3D space
    parfor x = 1:x_dim
        for y = 1:y_dim
            for z = 1:z_dim
                % Extract the voxel data across all echoes
                voxel_data = double(squeeze(img_data(x, y, z, :)));

                % Display voxel data for debugging
                disp(['Voxel (', num2str(x), ', ', num2str(y), ', ', num2str(z), '): ', num2str(voxel_data')]);

                if all(voxel_data == 0)
                    continue;
                end

                % Perform exponential fit
                fit_options = fitoptions('Method', 'NonlinearLeastSquares', 'StartPoint', [max(voxel_data), 50]);
                fit_type = fittype('a*exp(-x/b)', 'options', fit_options);
                [fit_obj, gof] = fit(echo_times', voxel_data, fit_type);

                
                %figure, plot(fit_obj,echo_times', voxel_data)
                % Display fitted parameters for debugging
                disp(['Fitted parameters for Voxel (', num2str(x), ', ', num2str(y), ', ', num2str(z), '): ', num2str(coeffvalues(fit_obj))]);

                % Extract T2 value and store it
                coeffs = coeffvalues(fit_obj);
                T2_map(x, y, z) = coeffs(2);
                S0(x, y, z) = coeffs(1);
                goodnessFit(x, y, z) = gof.rsquare;
            end
        end
    end
    %% 

    % Save the T2_map variable in the specified folder
    save(fullfile(t2maps_path, 'T2_map.mat'), 'T2_map', 'S0', 'goodnessFit');
end
