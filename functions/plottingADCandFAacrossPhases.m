function plottingADCandFAacrossPhases(physio, signal, physio_bin, roi_pvsas, ...
    roi_sas, nPhases, phasesLoaded)

cardiac = phasesLoaded;

%% Extract mean ADC over phases for each ROI
extract_roi_means = @(data, roi) cellfun(@(d) mean(d.data(roi)), data);

card_pvsas = extract_roi_means(cardiac, roi_pvsas);
card_sas   = extract_roi_means(cardiac, roi_sas);


if strcmp(signal, 'FA')
    ymax = 1;
    ymin = 0;
    
else
    ymax = 0.055;
    ymin = 0;
end


%% Plot mean across phases for each condition
figure; 
subplot(1,2,1)
plot(1:nPhases, card_pvsas, '-o'); hold on
title('PVSAS ROI'); xlabel('Phase'); ylabel(['Mean' signal]);

plot(1:nPhases, card_sas)
title('PVSAS vs. SAS ROI'); xlabel('Phase'); ylabel(['Mean' signal]);
legend({'PVSAS','SAS'}); hold on

%% Normalize SAS by mean across phases
norm_pvsas_cardiac = card_pvsas / mean(card_pvsas);
norm_sas_cardiac = card_sas / mean(card_sas);

subplot(1,2,2); hold on
plot(1:nPhases, norm_pvsas_cardiac, '-o'); hold on
plot(1:nPhases, norm_sas_cardiac, '-o')
title('PVSAS and SAS normalized by phase mean'); 
xlabel('Phase'); ylabel(['Normalized Mean' signal]);
legend({'PVSAS','SAS'})


  %% Prepare data
% Assuming you already have 'cardiac' and 'roi_pvsas' loaded

nPhases = numel(cardiac);

% Get indices of voxels in ROI
voxel_idx = find(roi_pvsas);

% Extract voxel-wise ADC values across all phases
voxel_values = cellfun(@(d) d.data(voxel_idx), cardiac, 'UniformOutput', false);
voxel_values = cat(2, voxel_values{:});  % each column = phase

% Plot each voxel's ADC across phases
figure;
hold on;
subplot(1,4,1)
plot(1:nPhases, voxel_values', 'Color', [0.6 0.6 1]); hold on

% Compute and plot the mean across voxels at each phase
mean_vals = mean(voxel_values, 1, 'omitnan');
plot(1:nPhases, mean_vals, 'b-', 'LineWidth', 2); hold on
ylim([ymin ymax]);
subtitle(['PVSAS across phases: ' signal]); hold on;

% Get indices of voxels in ROI
voxel_idx = find(roi_sas);

% Extract voxel-wise ADC values across all phases
voxel_values = cellfun(@(d) d.data(voxel_idx), cardiac, 'UniformOutput', false);
voxel_values = cat(2, voxel_values{:});  % each column = phase

hold on;
subplot(1,4,2); hold on
plot(1:nPhases, voxel_values', 'Color', [0.6 0.6 1]); 

% Compute and plot the mean across voxels at each phase
mean_vals = mean(voxel_values, 1, 'omitnan'); hold on;
plot(1:nPhases, mean_vals, 'b-', 'LineWidth', 2);
ylim([ymin ymax]);
xlabel('Cardiac Phase');
ylabel('ADC');
subtitle(['SAS across phases: ' signal]); hold on;


%% normalized

nPhases = numel(cardiac);

%% PVSAS ROI
voxel_idx = find(roi_pvsas);
voxel_values = cellfun(@(d) d.data(voxel_idx), cardiac, 'UniformOutput', false);
voxel_values = cat(2, voxel_values{:});  % each column = phase

% Normalize each voxel by its mean across phases
voxel_values_norm = voxel_values ./ mean(voxel_values, 2);

% Plot normalized voxel-wise ADC

subplot(1,4,3)
plot(1:nPhases, voxel_values_norm', 'Color', [0.6 0.6 1]); hold on

% Mean across voxels (normalized)
mean_vals_norm = mean(voxel_values_norm, 1, 'omitnan');
plot(1:nPhases, mean_vals_norm, 'b-', 'LineWidth', 2);

ylim([0.8 1.2]);  % since normalized
subtitle(['Normalized PVSASacross phases: ' signal]);
xlabel('Cardiac Phase'); ylabel(['Normalized ' signal]);

%% SAS ROI
voxel_idx = find(roi_sas);
voxel_values = cellfun(@(d) d.data(voxel_idx), cardiac, 'UniformOutput', false);
voxel_values = cat(2, voxel_values{:});  % each column = phase

% Normalize each voxel by its mean across phases
voxel_values_norm = voxel_values ./ mean(voxel_values, 2);

subplot(1,4,4)
plot(1:nPhases, voxel_values_norm', 'Color', [0.6 0.6 1]); hold on
mean_vals_norm = mean(voxel_values_norm, 1, 'omitnan');
plot(1:nPhases, mean_vals_norm, 'b-', 'LineWidth', 2);

ylim([0.8 1.2]);
subtitle(['Normalized SAS across phases:' signal]);
xlabel('Cardiac Phase'); ylabel(['Normalized' signal]);



end