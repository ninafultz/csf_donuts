%% plotting against eachother 
projPath = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\';
physioConditions = {'cardiac', 'resp','random'};


%% SUBJECTS
subjectDirs = dir(projPath);
subjectDirs = subjectDirs([subjectDirs.isdir]);
subjectDirs = subjectDirs(contains({subjectDirs.name}, 'Reconstruction'));


pvsas_voxel_values = physio_phase.m1_right_internaldonut.pvsas_voxel_values_cardiac_ADC;
sas_voxel_values = physio_phase.m1_right_internaldonut.sas_voxel_values_cardiac_ADC;

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

figure;

for i = 1:nSubjects
    y = SAS_ADC_Normalized(i,:);
    
    % Estimate zero-crossings and initial guess
    yu = max(y); yl = min(y); yr = yu-yl; yz = y - yu + yr/2;
    zx = x(yz .* circshift(yz,[0 1]) <= 0);
    per = 2*mean(diff(zx)); ym = mean(y);
    
    % Fit function
    fit_func = @(b,x) b(1)*sin(2*pi*x/b(2) + b(3)) + b(4);
    fcn = @(b) sum((fit_func(b,x) - y).^2);
    b0 = [yr, per, -1, ym];
    s = fminsearch(fcn, b0);

    yfit = fit_func(s, xp);
    A = s(1); offset = s(4);
    phase = s(3);
    
    % --- Store the amplitude ---
    MaxAmp_SAS(i) = A;
    
    % Plot 
    subplot(ceil(nSubjects/3),3,i)
    plot(x, y, 'bo','MarkerFaceColor','b'); hold on
    plot(xp, yfit, 'r-', 'LineWidth',1.5)
    
    % mark amplitude peak
    [~, idx] = max(yfit);
    plot(xp(idx), yfit(idx), 'ks','MarkerFaceColor','k','MarkerSize',8)
    
    grid on
    xlabel('Phase')
    ylabel('Signal')
    title(sprintf('voxel %d: A=%.2f', i, A))
end

%%

[nSubjects, nPhases] = size(PVSAS_ADC_Normalized);
x = 1:nPhases;
xp = linspace(min(x), max(x), 100);

MaxAmp_PVSAS = zeros(nSubjects,1);   % preallocate

figure;

for i = 1:nSubjects
    y = PVSAS_ADC_Normalized(i,:);
    
    % Estimate zero-crossings and initial guess
    yu = max(y); yl = min(y); yr = yu-yl; yz = y - yu + yr/2;
    zx = x(yz .* circshift(yz,[0 1]) <= 0);
    per = 2*mean(diff(zx)); ym = mean(y);
    
    % Fit function
    fit_func = @(b,x) b(1)*sin(2*pi*x/b(2) + b(3)) + b(4);
    fcn = @(b) sum((fit_func(b,x) - y).^2);
    b0 = [yr, per, -1, ym];
    s = fminsearch(fcn, b0);

    yfit = fit_func(s, xp);
    A = s(1); offset = s(4);
    phase = s(3);
    
    % --- Store the amplitude ---
    MaxAmp_PVSAS(i) = A;
    
    % Plot 
    subplot(ceil(nSubjects/3),3,i)
    plot(x, y, 'bo','MarkerFaceColor','b'); hold on
    plot(xp, yfit, 'r-', 'LineWidth',1.5)
    
    % mark amplitude peak
    [~, idx] = max(yfit);
    plot(xp(idx), yfit(idx), 'ks','MarkerFaceColor','k','MarkerSize',8)
   
    xlabel('Phase')
    ylabel('Signal')
    title(sprintf('voxel %d: A=%.2f', i, A))
end
%%




%%
figure;
hold on   % allow multiple plots on the same axes

% PVSAS in blue
scatter(mean(pvsas_voxel_values,2), MaxAmp_PVSAS, 80, 'b', 'filled');

% SAS in red
scatter(mean(sas_voxel_values,2), MaxAmp_SAS, 80, 'r', 'filled');
ylim([-5 5])
xlabel('ADC (mean across phases)');
ylabel('Max Amplitude (fit)');
title('PVSAS vs SAS Max Amplitude');
grid on;

legend('PVSAS', 'SAS');


%%

figure;
hold on   % allow multiple plots on the same axes

% PVSAS in blue
scatter(mean(PVSAS_ADC_Normalized,2), MaxAmp_PVSAS, 80, 'b', 'filled');

% SAS in red
scatter(mean(SAS_ADC_Normalized,2), MaxAmp_SAS, 80, 'r', 'filled');
ylim([-5 5])
xlabel('Normalized ADC (mean across phases)');
ylabel('Max Amplitude (fit)');
title('PVSAS vs SAS Max Amplitude');
grid on;

legend('PVSAS', 'SAS');


%%

figure;
hold on

% PVSAS in blue
scatter(mean(pvsas_voxel_values,2), MaxAmp_PVSAS, 80, 'b', 'filled');
[pvsas_r, pvsas_p] = corr(mean(pvsas_voxel_values,2), MaxAmp_PVSAS);
% Plot regression line
p = polyfit(mean(pvsas_voxel_values,2), MaxAmp_PVSAS, 1);
xfit = linspace(min(mean(pvsas_voxel_values,2)), max(mean(pvsas_voxel_values,2)), 100);
yfit = polyval(p, xfit);
plot(xfit, yfit, 'b--', 'LineWidth', 1.5);

% SAS in red
scatter(mean(sas_voxel_values,2), MaxAmp_SAS, 80, 'r', 'filled');
[sas_r, sas_p] = corr(mean(sas_voxel_values,2), MaxAmp_SAS);
p = polyfit(mean(sas_voxel_values,2), MaxAmp_SAS, 1);
xfit = linspace(min(mean(sas_voxel_values,2)), max(mean(sas_voxel_values,2)), 100);
yfit = polyval(p, xfit);
plot(xfit, yfit, 'r--', 'LineWidth', 1.5);

ylim([-5 5])
xlabel('ADC (mean across phases)');
ylabel('Max Amplitude (fit)');
title('PVSAS vs SAS Max Amplitude');
grid on;
legend('PVSAS','PVSAS fit','SAS','SAS fit');

% Display correlation coefficients in command window
fprintf('PVSAS: r = %.3f, p = %.3f\n', pvsas_r, pvsas_p);
fprintf('SAS:   r = %.3f, p = %.3f\n', sas_r, sas_p);


%%

% Find indices of SAS values within the desired range
valid_idx = (MaxAmp_SAS >= -40) & (MaxAmp_SAS <= 20);

% Filter SAS data
SAS_ADC_Filtered    = sas_voxel_values(valid_idx,:);
MaxAmp_SAS_Filtered = MaxAmp_SAS(valid_idx);

PVSAS_ADC_Filtered    = pvsas_voxel_values;
MaxAmp_PVSAS_Filtered = MaxAmp_PVSAS;


figure;
hold on

% PVSAS
scatter(mean(PVSAS_ADC_Filtered,2), MaxAmp_PVSAS_Filtered, 80, 'b', 'filled');
[pvsas_r, pvsas_p] = corr(mean(PVSAS_ADC_Filtered,2), MaxAmp_PVSAS_Filtered);

% SAS
scatter(mean(SAS_ADC_Filtered,2), MaxAmp_SAS_Filtered, 80, 'r', 'filled');
[sas_r, sas_p] = corr(mean(SAS_ADC_Filtered,2), MaxAmp_SAS_Filtered);

ylim([-5 5])
xlabel('ADC (mean across phases)');
ylabel('Max Amplitude (fit)');
title('PVSAS vs SAS Max Amplitude (Filtered SAS)');
grid on;
legend('PVSAS','SAS');

fprintf('PVSAS: r = %.3f, p = %.3f\n', pvsas_r, pvsas_p);
fprintf('SAS:   r = %.3f, p = %.3f\n', sas_r, sas_p);


%%

