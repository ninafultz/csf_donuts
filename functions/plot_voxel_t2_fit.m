function plot_voxel_t2_fit(echo_times, T2_map, goodnessFit, x, y, z)
%% 

    % Extract voxel data
    voxel_data = squeeze(T2_map(x, y, z, :));
    
    % Check if the voxel data is all zeros
    if all(voxel_data == 0)
        disp('The selected voxel data is all zeros.');
        return;
    end
    %% 
 
    %% 
    
    

        % Extract T2 value and goodness of fit
        T2_value = coeffvalues(fit_obj);
        rsquare = gof.rsquare;
        
        % Create figure with white background
        figure('Color', 'white');
        
        % Plot the voxel data and the fitted curve
        subplot(1, 1, 1); % Plot T2 fit in the first subplot
        plot(echo_times, voxel_data, 'bo', 'MarkerFaceColor', 'b', 'DisplayName', 'Voxel Data'); hold on;
        plot(echo_times, feval(fit_obj, echo_times), 'r-', 'DisplayName', 'Fitted Curve');
        xlabel('Echo Time (ms)');
        ylabel('Signal Intensity');
        title(['Voxel (', num2str(x), ', ', num2str(y), ', ', num2str(z), ') T2 Fit']);
        legend;
        hold off;
        
        % Display T2 value and goodness of fit
        disp(['Voxel (', num2str(x), ', ', num2str(y), ', ', num2str(z), '):']);
        disp(['  T2 Value: ', num2str(T2_value(2))]);
        disp(['  Goodness of Fit (R^2): ', num2str(rsquare)]);
        

end
