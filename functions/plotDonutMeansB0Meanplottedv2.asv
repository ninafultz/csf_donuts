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



            %%  create new x vector
b0_flipped = flip(b0Values);
indXzero = find(abs(x_mm)<eps);
xspacing_zero_array = 0:numel(indXzero)-1;
x_mm_new = x_mm;
x_mm_new(indXzero) = xspacing_zero_array;
% shift left hand side non zero x  values (to have correct spacing)
indleft = (1:min(indXzero)-1);
x_mm_new(indleft) = x_mm(indleft) + xspacing_zero_array(1);
% shift right hand side non zero x  values (to have correct spacing)
indright = (max(indXzero)+1:numel(x_mm));
x_mm_new(indright) = x_mm(indright) + xspacing_zero_array(end);
% original plot labels 
xlabels = num2str(x_mm); % plot "true" x_mm values at the specified ticks positions
% new plot x labels 
xi_left  = (floor(min(x_mm)):-1);
xi_right  = (1:ceil(max(x_mm)));
xi = [xi_left zeros(1,numel(indXzero)) xi_right] ; 
xi_labels = num2str(xi');
xi_ticks = [xi_left (0:numel(indXzero)-1) xi_right+numel(indXzero)-1] ; 

            
%% 

            b0_flipped2 = flip(b0_flipped);
            
        
            figure('Name', 'ADC and B0 Profiles Collapsed', 'NumberTitle', 'off');
            set(gcf, 'Color', 'w', 'Renderer', 'Painters');  % Set background color to white

            yyaxis left
            plot(x_mm_new, adcValues, '-o', ...
                'Color', [0.7, 0.7, 0.7], 'LineWidth', 1, ...
                'MarkerFaceColor', [0.7, 0.7, 0.7], 'MarkerSize', 4, ...
                'DisplayName', ['ADC - ', roi_name{1}]);
            ylabel('CSF-mobility (mm2/s)');
            
            ylim([0 0.11]);
            yticks(0:0.02:0.11);

            yyaxis right
            fill([(x_mm_new'), flip((x_mm_new'))], ...
                 [double(b0_flipped2)', zeros(1, length(b0_flipped2))], ...
                 [0.5, 0.8, 1], 'FaceAlpha', 0.3, ...
                 'EdgeColor', 'none', 'DisplayName', ['B0 - ', roi_name{1}]);
            ylabel('Non-motion senitized Values');
            xlabel('Distance from Vessel (mm)')
            set(gca, 'XTick', xi_ticks, 'XTickLabel', xi_labels);
            set(gca, 'XDir','reverse')
            ylim([0 600]);
            %xlim([min(x_mm_new) max(x_mm_new)])
            yticks(0:100:600);

%% checking to make sure the voxel size and everything matches....
% figure(1)  
% % your original plot
% subplot(2,1,1)
% plot(x_mm_new,adcValues,'-*');
% set(gca, 'XDir','reverse')
% 
% set(gca,'XTick',x_mm_new,'XTickLabel',xlabels);
% grid on 
% % modified plot
% subplot(2,1,2)
% plot(x_mm_new,adcValues,'-*');
% set(gca, 'XTick', xi_ticks, 'XTickLabel', xi_labels);
% set(gca, 'XDir','reverse')
% grid on 
            
        end
    end

end

