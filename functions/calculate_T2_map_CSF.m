function [T2_map_CSF, S0, goodnessFit] = calculate_T2_map_CSF(img_data, echo_times, t2maps_path, wm_average)
    % Initialize the dimensions
    [x_dim, y_dim, z_dim, num_echoes] = size(img_data);

    % Preallocate the T2_map matrix for each echo
    T2_map_CSF = zeros(x_dim, y_dim, z_dim);
    S0 = zeros(x_dim, y_dim, z_dim);
    goodnessFit = zeros(x_dim, y_dim, z_dim);
    
    % Loop through each voxel in the 3D space
    parfor x = 1:x_dim
        for y = 1:y_dim
            for z = 1:z_dim
                % Extract the voxel data across all echoes
                voxel_data = double(squeeze(img_data(x, y, z, :)));

                % Skip fitting if the voxel data is all zeros
                if all(voxel_data == 0)
                    continue;
                end
                
            % Define the biexponential model with fixed T2_1 = wm_average
            biexp_model = fittype('S0*(alpha * exp(-t / T2_wm) + (1-alpha) * exp(-t / T2_2))', ...
                'independent', 't', 'coefficients', {'S0', 'alpha', 'T2_2'}, 'problem', 'T2_wm');

            % Fit the model to the data, fixing T2_1 to wm_average
            [fit_obj, gof] = fit(echo_times', voxel_data, biexp_model, ...
                'Lower', [0, 0, 0], 'Upper', [Inf, 1, 10000], ...
                'StartPoint', [max(voxel_data), 0.5, 1000], 'problem', wm_average);

                % Extract fitted parameters
                coeffs = coeffvalues(fit_obj);
                T2_map_CSF(x, y, z) = coeffs(3);  % T2_2 is now stored in T2_map
                S0(x, y, z) = coeffs(1);      % S0 is stored
                goodnessFit(x, y, z) = gof.rsquare;  % Goodness of fit (R^2) stored
            end
        end
    end

    % Save the T2_map variable in the specified folder
    save(fullfile(t2maps_path, 'T2_map_CSF.mat'), 'T2_map', 'S0', 'goodnessFit');
end
