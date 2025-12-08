function plottingADCandFAacrossPhasesAllSubjectsACA(physio, signal, physio_bin, roi_pvsas, ...
     nPhases, phasesLoaded, roiName, subject_code);

cardiac = phasesLoaded;

%% Extract mean ADC or FA over phases for each ROI

if strcmp(signal, 'FA')
    ymax = 1; ymin = 0;
else
    ymax = 0.055; ymin = 0;
end

%% Plot mean across phases
% Define output directory
outputDir = 'R:\- Gorter\- Personal folders\Fultz, N\scripts\csfdonuts_lydiane\plots\nov112025';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% %% Plot mean across phases
% f1 = figure; 
% subplot(1,2,1)
% plot(1:nPhases, card_pvsas, '-o'); hold on
% plot(1:nPhases, card_sas)
% subtitle(sprintf('Mean %s', signal));
% xlabel('Phase'); ylabel(['Mean ' signal]);
% legend({'PVSAS','SAS'});
% 
% % Normalize by mean across phases
% norm_pvsas_cardiac = card_pvsas / mean(card_pvsas);
% norm_sas_cardiac = card_sas / mean(card_sas);
% 
% subplot(1,2,2); hold on
% plot(1:nPhases, norm_pvsas_cardiac, '-o'); 
% plot(1:nPhases, norm_sas_cardiac, '-o')
% subtitle(sprintf('Mean %s', signal));
% title(sprintf('%s - %s - %s - Normalized %s', subject_code, roiName, physio, signal)); 
% xlabel('Phase'); ylabel(['Normalized ' signal]);
% legend({'PVSAS','SAS'});
% 
% % Save first figure
% saveas(f1, fullfile(outputDir, sprintf('%s_%s_%s_%s_meanplots.png', subject_code, roiName, physio, signal)));

%% pvsas
nPhases = numel(phasesLoaded);

% Preallocate voxel matrix
nVoxels = nnz(roi_pvsas);      % number of voxels in ROI
voxel_values_pvsas = zeros(nVoxels, nPhases);

% Extract voxel values for each phase
for t = 1:nPhases
    vol = phasesLoaded{1,t}.data;
    voxel_values_pvsas(:,t) = vol(roi_pvsas);
end

% Normalize across voxels (optional)
voxel_values_norm_pvsas = voxel_values_pvsas ./ mean(voxel_values_pvsas,2);

% Mean across voxels per phase
card_pvsas = mean(voxel_values_pvsas,1,'omitnan');
norm_pvsas_cardiac = mean(voxel_values_norm_pvsas,1,'omitnan');



%%
f2 = figure;
subplot(1,2,1)
plot(1:nPhases, voxel_values_pvsas', 'Color', [0.6 0.6 1]); hold on
plot(1:nPhases, card_pvsas, 'b-', 'LineWidth', 2)
ylim([ymin ymax])
subtitle(sprintf('PVSAS: %s ', signal));

% Normalized PVSAS voxel-wise
subplot(1,2,2)
plot(1:nPhases, voxel_values_norm_pvsas', 'Color', [0.6 0.6 1]); hold on
plot(1:nPhases, norm_pvsas_cardiac, 'b-', 'LineWidth', 2)
ylim([0.8 1.2])
subtitle(sprintf('Normalized PVSAS: %s ', signal));
title(sprintf('%s - %s - %s - %s', subject_code, roiName, physio, signal));


% Save second figure
saveas(f2, fullfile(outputDir, sprintf('%s_%s_%s_%s_voxelwise.png', subject_code, roiName, physio, signal)));


%% saving variables for future use: 
cd(physio_bin);

%% Ensure physio_bin and subfields exist

physio_phase = struct();

if ~isfield(physio_phase, roiName) || ~isstruct(physio_phase.(roiName))
    physio_phase.(roiName) = struct();
end

% Construct dynamic field names
pvsas_field        = sprintf('pvsas_%s_%s', physio, signal);
norm_pvsas_field   = sprintf('norm_pvsas_%s_%s', physio, signal);
pvsas_voxel_values_field = sprintf('pvsas_voxel_values_%s_%s', physio, signal);

% Store results into physio_bin.(roiName)
physio_phase.(roiName).(pvsas_field)              = card_pvsas;
physio_phase.(roiName).(norm_pvsas_field)         = norm_pvsas_cardiac;
physio_phase.(roiName).(pvsas_voxel_values_field) = voxel_values_pvsas;

saveFile = fullfile(physio_bin, sprintf('%s_%s_%s_%s_physio_phase_thr50.mat', subject_code, roiName, physio, signal));

%% Save structure
% This will create or overwrite a .mat file containing physio_phase
save(saveFile, 'physio_phase');

% Optionally, display confirmation
fprintf('Saved results in physio_bin folder: physio_phase.%s for %s - %s - %s\n', ...
    roiName, physio, signal, subject_code);

end
