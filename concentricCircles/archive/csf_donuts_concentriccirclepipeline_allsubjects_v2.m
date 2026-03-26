% csf donut protocol for CAA patients 
% nina fultz january 2026
% n.e.fultz@lumc.nl
% 

%% output:
    % 1) circleShells_10_intersection.nii which will be the concentric circles 
    % on the non-motion sensitized image

%%
% to do:
% mask into regions - separating m1 vs. m2 - regional flow territories 
% to do:
    % look at arterial diameter calculations
    % plot individual radial trajectories, compare across diameters
    % look at all different vessels 

    % goal with paper:
        %1) show russian doll concentric circles
        %2) rate donuts around arteries
        %3) overall area of high mobility around vessels (m1, m2) 
        %4) non russian doll concentric circles
        %5) regional flow territories

%% goals:
clear
clc
%%
% defining paths 
project_directory = 'R:\- Gorter\- Personal folders\Fultz, N\';
project_name      = 'csfdonuts_lydiane'
scripts           = fullfile(project_directory, 'scripts', project_name);

%%params
voxSize = 0.45; % voxel size mm
maxDist = 10; % distance away from vessel - mm 
binWidth = 0.45; % bins - probs same as your voxsize - mm

addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts)));

ROI = 'M1';

subject_list = {  
    '20191022_Reconstruction' 
    '20201020_Reconstruction'
    '20201111_Reconstruction' 
    '20191210_Reconstruction' 
    '20201019_Reconstruction' 
    '20201110_Reconstruction'}

AllMeanADC = cell(1, numel(subject_list));
AllMeanB0 = cell(1, numel(subject_list));

for k = 1:numel(subject_list)

subject_code = subject_list{k}
%% paths

subjPath                 = fullfile(project_directory, project_name, subject_code);
reorientedDir            = fullfile(subjPath, 'reoriented');
regDir                   = fullfile(subjPath, 'reg');
CCDir                   = fullfile(subjPath, '\', 'concentricCircles');
ROIsDir                   = fullfile(subjPath, '\', 'ROIs');
mkdir(CCDir);
cd(reorientedDir);
MRScriptsDir             = fullfile(scripts, 'mr_analysis');
addpath(genpath(fullfile(project_directory, project_name, subject_code)));

%% loading t1, csf mobility 


        V = spm_vol('3dT1_0.9mm_to_B0_properOrientation.nii'); % USE BIASFIELD CORRECTED SCAN
        t1 = spm_read_vols(V);
        
        adcFile = 'masked_b0_ADC_mhd_thr150.0000.nii';
        adcV = spm_vol(adcFile);
        adc = spm_read_vols(adcV);
        info = niftiinfo(adcFile);
        
        b0 = spm_vol('B0_from_mhd.nii');
        b0_seg = spm_read_vols(b0);
        
        cd(ROIsDir);
        V = spm_vol(['parsing' ROI '.nii']);
        vesselmask = spm_read_vols(V);
        
        cd(reorientedDir);
        t1vessel = spm_vol('t1_vessel.nii');
        t1vesselmask = spm_read_vols(t1vessel);
        
        t1mask_inROI = t1vesselmask .* (vesselmask > 0);

        % figure;
        % imshow3Dfull(t1mask_inROI); 
        % vessel = t1mask_inROI;
        % 
        % 
        % figure;
        % imshow3Dfull(b0_thresh); 
        %% registration files, run in shark because of dependencies and path issues
        
        %% show t1 and adc 
        % % % figure;
        % % % imshow3Dfull(t1); 
        % % % 
        % % % figure;
        % % % imshow3Dfull(adc, [0 0.05]);
        
        
        %% plotting seed, making concentric circles

if ~exist(fullfile(CCDir, ['circleShells_10_parsing' ROI '.nii']), 'file');

        vars.t1       = t1;
        vars.vessel   = t1mask_inROI;
        vars.adc      = adc;
        vars.subjPath = subjPath;
        vars.b0_thresh = b0_thresh;
        vars.info = info;
        vars.binWidth = binWidth;
        vars.voxSize = voxSize;
        vars.maxDist = maxDist;
        vars.ROI = ROI;
        
        concentricCircles(vars);

%%
else
            cd(CCDir);
            
            V = spm_vol(['circleShells_10_parsing' ROI '.nii']);
            circleLabelsMasked = spm_read_vols(V);
            
            nBins = double(max(circleLabelsMasked(:)));
            
            meanADC = nan(nBins,1);
            stdADC  = nan(nBins,1);
            nVoxels = zeros(nBins,1);
            allVals = cell(1,nBins);
            meanB0 = nan(nBins,1);
            stdB0  = nan(nBins,1);
            
            for i = 1:nBins
            
                mask = (circleLabelsMasked == i);
                vals = adc(mask & adc ~= 0);
                b0_vals = b0_seg(mask);
            
                allVals{i} = vals;
            
                if ~isempty(vals)
                    meanADC(i) = median(double(vals));
                    stdADC(i)  = std(double(vals));
                    nVoxels(i) = numel(vals);
                    meanB0(i) = median(double(b0_vals));
                    stdB0(i)  = std(double(b0_vals));
                end
            end
            
            binCenters = (1:nBins) * binWidth;
            
            upper = meanADC + stdADC;
            lower = meanADC - stdADC;
            
            upperB0 = meanB0 + stdB0;
            lowerB0 = meanB0 - stdB0;
            
            figure; hold on;
            
            yyaxis left
            fill([binCenters fliplr(binCenters)], ...
                 [upper' fliplr(lower')], ...
                 [0.5 0.7 1], 'EdgeColor','none', 'FaceAlpha',0.4);
            plot(binCenters, meanADC, 'b-', 'LineWidth',2);
            ylabel('csf-mobility');
            ylim([0.02 0.04]);
            xlim([0.45 4]);
            
            yyaxis right
            fill([binCenters fliplr(binCenters)], ...
                 [upperB0' fliplr(lowerB0')], ...
                 [1 0.65 0], 'EdgeColor','none', 'FaceAlpha',0.4);
            plot(binCenters, meanB0, '-', 'LineWidth',2);
            ylim([0 1000]);
            ylabel(['non-motionsensitized scan']);
            xlim([0.45 4]);
            % ylabel('B0');   % if you want a right y-label
            
            xlabel('Dilation (mm)');
            title(['CSF ' ROI])
            hold off;

            % collecting all
            AllMeanADC{k} = meanADC;
            AllMeanB0{k} = meanB0;


            cd(CCDir);
            save(['meanCSFmobility_CC' ROI '_150_median.mat'], 'meanADC');
            save(['meanB0_CC' ROI '_150_median.mat'], 'meanB0');

            %% comparing the bins with box plots 
            
            % Remap labels: bins 1-2 → "inner" (0-0.9mm), bins 3+ → "outer" (>0.9mm)
            threshold_bin = 4; % 2 bins * 0.45mm = 0.9mm
            
            circleLabelsMasked_remapped = zeros(size(circleLabelsMasked));
            circleLabelsMasked_remapped(circleLabelsMasked > 0 & circleLabelsMasked <= threshold_bin) = 1; % Inner
            circleLabelsMasked_remapped(circleLabelsMasked > threshold_bin) = 2; % Outer
            
            % Now analyze only 2 groups
            nBins = 2;
            meanADC = nan(nBins,1);
            stdADC  = nan(nBins,1);
            nVoxels = zeros(nBins,1);
            allVals = cell(1,nBins);
            
            for i = 1:nBins
                mask = (circleLabelsMasked_remapped == i);
                vals = adc(mask & adc ~= 0);
                allVals{i} = vals;
                if ~isempty(vals)
                    meanADC(i) = median(double(vals));
                    stdADC(i)  = std(double(vals));
                    nVoxels(i) = numel(vals);
                end
            end
            
            % Plot as bar chart or comparison
            groupNames = {'Inner', 'Outer'};
            
            figure; 
            subplot(1,1,1);
            bar(1:nBins, meanADC);
            hold on;
            errorbar(1:nBins, meanADC, stdADC, 'k.', 'LineWidth', 1.5);
            set(gca, 'XTick', 1:nBins, 'XTickLabel', groupNames);
            ylabel('CSF-mobility');
            title(['Mean ADC ' ROI]);
            grid on;
            
            % Print statistics
            fprintf('\n--- Region Statistics ---\n');
            for i = 1:nBins
                fprintf('%s: Mean=%.6f, Std=%.6f, N=%d voxels\n', ...
                    groupNames{i}, meanADC(i), stdADC(i), nVoxels(i));
            end
            
            % Optional: statistical test
            if ~isempty(allVals{1}) && ~isempty(allVals{2})
                [h, p] = ttest2(allVals{1}, allVals{2});
                fprintf('\nTwo-sample t-test: p = %.4f', p);
                if h
                    fprintf(' (SIGNIFICANT difference)\n');
                else
                    fprintf(' (no significant difference)\n');
                end
            end


%%

            % Original number of bins
            nBinsOriginal = double(max(circleLabelsMasked(:)));
            
            % Combine every two bins
            nBinsCombined = ceil(nBinsOriginal / 2);
            meanADC = nan(nBinsCombined, 1);
            stdADC  = nan(nBinsCombined, 1);
            nVoxels = zeros(nBinsCombined, 1);
            allVals = cell(1, nBinsCombined);
            
            for i = 1:nBinsCombined
                % Determine which original bins to combine
                bin1 = 2*i - 1;
                bin2 = 2*i;
                
                % Get mask for combined bins
                mask = (circleLabelsMasked == bin1);
                if bin2 <= nBinsOriginal
                    mask = mask | (circleLabelsMasked == bin2);
                end
                
                vals = adc(mask & adc ~= 0);
                allVals{i} = vals;
                
                if ~isempty(vals)
                    meanADC(i) = median(double(vals));
                    stdADC(i)  = std(double(vals));
                    nVoxels(i) = numel(vals);
                end
            end
            
            % Bin centers for combined bins (each represents 2x binWidth)
            binCenters = (1:nBinsCombined) * (2 * binWidth);
            
            upper = meanADC + stdADC;
            lower = meanADC - stdADC;
            
            figure; hold on;
            fill([binCenters fliplr(binCenters)], ...
                 [upper' fliplr(lower')], ...
                 [0.8 0.8 0.8], 'EdgeColor','none', 'FaceAlpha',0.4);
            plot(binCenters, meanADC, 'k-', 'LineWidth',2);
            xlabel('Dilation (mm)');
            ylabel(['csf-mobility ' ROI]);
            xlim([0 maxDist]);
            %ylim([0 0.005])
            hold off;
            
            fprintf('Combined %d original bins into %d bins\n', nBinsOriginal, nBinsCombined);

            close all; 
end
end




% l