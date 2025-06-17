function segmented_region = regiongrowing_v2(image, seed_point, seed_value, tolerance)
    % Create a binary mask for the segmented region
    [rows, cols] = size(image);
    segmented_region = false(rows, cols);
    region_pixels = false(rows, cols);
    region_pixels(seed_point(1), seed_point(2)) = true;
    segmented_region(seed_point(1), seed_point(2)) = true;
    
    % Initialize queue
    queue = seed_point;
    
    while ~isempty(queue)
        % Dequeue the next pixel
        current_pixel = queue(1, :);
        queue(1, :) = [];
        r = current_pixel(1);
        c = current_pixel(2);
        
        % Check 8-connected neighbors
        for dr = -1:1
            for dc = -1:1
                if dr ~= 0 || dc ~= 0
                    nr = r + dr;
                    nc = c + dc;
                    
                    if nr > 0 && nr <= rows && nc > 0 && nc <= cols
                        if ~segmented_region(nr, nc)
                            if abs(image(nr, nc) - seed_value) <= tolerance
                                segmented_region(nr, nc) = true;
                                queue = [queue; nr, nc];
                            end
                        end
                    end
                end
            end
        end
    end
end
