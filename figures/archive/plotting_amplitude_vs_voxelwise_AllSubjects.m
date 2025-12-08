%% plotting against eachother 
projPath = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\';
physio= 'cardiac';
signal = 'ADC';
roi = 'm1_right_internaldonut';

%% SUBJECTS
subjectDirs = dir(projPath);
subjectDirs = subjectDirs([subjectDirs.isdir]);
subjectDirs = subjectDirs(contains({subjectDirs.name}, 'Reconstruction'));

All_MaxAmp_SAS   = [];
All_MaxAmp_PVSAS = [];
All_mean_SAS     = [];
All_mean_PVSAS   = [];

for s = 1:numel(subjectDirs)
    
    subjPath = fullfile(projPath, subjectDirs(s).name, 'physio_binning');

    physioFile = [subjectDirs(s).name '_' roi '_'...
        physio '_' signal '_physio_phase_thr50.mat'];

    load(fullfile(subjPath, physioFile));


    pvsas_voxel_values = getfield(physio_phase, roi, ['pvsas_voxel_values_' physio '_' signal]);
    sas_voxel_values   = getfield(physio_phase, roi, ['sas_voxel_values_' physio '_' signal]);

    % PVSAS
    PVSAS_ADC_Normalized = (pvsas_voxel_values - mean(pvsas_voxel_values, 2)) ...
                            ./ mean(pvsas_voxel_values, 2) * 100;
    
    % SAS
    SAS_ADC_Normalized   = (sas_voxel_values - mean(sas_voxel_values, 2)) ...
                            ./ mean(sas_voxel_values, 2) * 100;

%%
    [nSubjects, nPhases] = size(SAS_ADC_Normalized);
    x = 1:nPhases;
    xp = linspace(min(x), max(x), 100);
    
    MaxAmp_SAS = zeros(nSubjects,1);   % preallocate
    
            %% Sinusoidal fit for SAS
            for i = 1:nSubjects
                y = SAS_ADC_Normalized(i,:);
                
                % Estimate zero-crossings and initial guess
                yu = max(y); yl = min(y); yr = yu-yl; yz = y - yu + yr/2;
                zx = x(yz .* circshift(yz,[0 1]) <= 0);
                per = 2*mean(diff(zx)); 
                ym = mean(y);
                
                % Fit function
                fit_func = @(b,x) b(1)*sin(2*pi*x/b(2) + b(3)) + b(4);
                fcn = @(b) sum((fit_func(b,x) - y).^2);
                b0 = [yr, per, -1, ym];
                
                % Fit using fminsearch
                s = fminsearch(fcn, b0);
                
                MaxAmp_SAS(i) = s(1);  % store amplitude
            end
            
            %% Sinusoidal fit for PVSAS
            [nSubjects, ~] = size(PVSAS_ADC_Normalized);
            MaxAmp_PVSAS = zeros(nSubjects,1);
            
            for i = 1:nSubjects
                y = PVSAS_ADC_Normalized(i,:);
                
                yu = max(y); yl = min(y); yr = yu-yl; yz = y - yu + yr/2;
                zx = x(yz .* circshift(yz,[0 1]) <= 0);
                per = 2*mean(diff(zx)); 
                ym = mean(y);
                
                fit_func = @(b,x) b(1)*sin(2*pi*x/b(2) + b(3)) + b(4);
                fcn = @(b) sum((fit_func(b,x) - y).^2);
                b0 = [yr, per, -1, ym];
                
                s = fminsearch(fcn, b0);
                
                MaxAmp_PVSAS(i) = s(1);
            end
            
            %% Collect results across subjects
            All_MaxAmp_SAS   = [All_MaxAmp_SAS; MaxAmp_SAS];
            All_MaxAmp_PVSAS = [All_MaxAmp_PVSAS; MaxAmp_PVSAS];
            All_mean_SAS     = [All_mean_SAS; mean(sas_voxel_values,2)];
            All_mean_PVSAS   = [All_mean_PVSAS; mean(pvsas_voxel_values,2)];
            % 
            % All_mean_SAS     = [All_mean_SAS; mean(SAS_ADC_Normalized,2)];
            % All_mean_PVSAS   = [All_mean_PVSAS; mean(PVSAS_ADC_Normalized,2)];
end


figure; hold on
scatter(All_mean_PVSAS, All_MaxAmp_PVSAS, 80,'b','filled');
scatter(All_mean_SAS,   All_MaxAmp_SAS,   80,'r','filled');
xlabel('ADC (mean across phases)');
ylabel('Max Amplitude (fit)');
title('PVSAS vs SAS Max Amplitude Across All Subjects');
grid on
legend('PVSAS','SAS');

[r, p] = corr(All_mean_PVSAS, All_MaxAmp_PVSAS);
any(isnan(All_mean_PVSAS))
any(isnan(All_MaxAmp_PVSAS))


[r, p] = corr(All_mean_SAS, All_MaxAmp_SAS);