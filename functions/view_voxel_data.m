function view_voxel_data(masked_par_data, T2_map, S0, goodnessFit)
    % Display the 3D image using imshow3Dfull
    figure;
    imshow3Dfull(masked_par_data(:,:,:,2)); % Show data from the 2nd echo
    
    % Set up the callback function for mouse click
    set(gcf, 'WindowButtonDownFcn', @voxel_callback);
    
    % Callback function to handle voxel selection
    function voxel_callback(~, ~)
        % Get the current point of the mouse click
        point = get(gca, 'CurrentPoint');
        x = round(point(1, 1));
        y = round(point(1, 2));
        z = round(getappdata(gcf, 'slice'));
        
        % Display voxel coordinates
        disp(['Selected Voxel: (', num2str(x), ', ', num2str(y), ', ', num2str(z), ')']);
        
        % Check if the selected voxel is within the bounds
        [x_dim, y_dim, z_dim, ~] = size(masked_par_data);
        if x > 0 && x <= x_dim && y > 0 && y <= y_dim && z > 0 && z <= z_dim
            % Extract and display voxel data
            voxel_data = squeeze(masked_par_data(x, y, z, :));
            disp(['Voxel Data: ', num2str(voxel_data')]);
            
            % Display T2, S0, and goodness of fit values
            disp(['T2 Value: ', num2str(T2_map(x, y, z))]);
            disp(['S0 Value: ', num2str(S0(x, y, z))]);
            disp(['Goodness of Fit: ', num2str(goodnessFit(x, y, z))]);
        else
            disp('Selected voxel is out of bounds.');
        end
    end
end
