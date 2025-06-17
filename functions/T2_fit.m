function [T2_map, S0_map] = T2_fit(x_dim, y_dim, z_dim, sub_boli_number, echotimes, average, gmmask)

    T2_map = NaN(x_dim, y_dim, z_dim, sub_boli_number);
    S0_map = NaN(x_dim, y_dim, z_dim, sub_boli_number);

    % Define the function for fitting
    func = @(TE, S0, T2) S0 .* exp(-TE ./ T2);

    for z = 1:z_dim
        for y = 1:y_dim
            for x = 1:x_dim
                for i = 1:sub_boli_number
                    if isnan(gmmask(x, y, z))
                        continue
                    else
                        xdata = echotimes;
                        ydata = squeeze(average(x, y, z, 1:7, i));
                        p0 = [ydata(1) * 0.7, 90];
                        disp(p0);
                        try
                            % Fit the data using lsqcurvefit
                            options = optimset('MaxFunEvals', 1000000000);
                            [popt, ~, ~, exitflag] = lsqcurvefit(func, p0, xdata, ydata, [], [], options);
                            if exitflag > 0
                                T2_map(x, y, z, i) = popt(2);
                                S0_map(x, y, z, i) = popt(1);
                            else
                                T2_map(x, y, z, i) = NaN;
                                S0_map(x, y, z, i) = NaN;
                            end
                        catch ME
                            fprintf('Error fitting voxel at (%d, %d, %d, %d): %s\n', x, y, z, i, ME.message);
                            T2_map(x, y, z, i) = NaN;
                            S0_map(x, y, z, i) = NaN;
                        end
                    end
                end
            end
        end
    end
end
