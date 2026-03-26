% csf donut protocol for CAA patients 
% nina fultz january 2026
% n.e.fultz@lumc.nl

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

ROIs = {'M1','M2'};

subject_list = {  
    '20191022_Reconstruction' 
    '20201020_Reconstruction'
    '20201111_Reconstruction' 
    '20191210_Reconstruction' 
    '20201019_Reconstruction' 
    '20201110_Reconstruction'}

dilationDiameter = [1:10];

for r = 1:numel(ROIs);
ROI = ROIs{r};
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
        
        adcFile = 'masked_b0_ADC_mhd_thr150.0000.nii';
        adcV = spm_vol(adcFile);
        adc = spm_read_vols(adcV);
        info = niftiinfo(adcFile);
        
        b0 = spm_vol('B0_from_mhd.nii');
        b0_seg = spm_read_vols(b0);
        b0Image = b0_seg;
        
        cd(ROIsDir);
        V = spm_vol(['parsing' ROI '.nii']);
        vesselmask = spm_read_vols(V);
        
        cd(reorientedDir);
        t1vessel = spm_vol('t1_vessel.nii');
        t1vesselmask = spm_read_vols(t1vessel);
        
        t1mask_inROI = t1vesselmask .* (vesselmask > 0);
        
        % figure;
        % imshow3Dfull(t1mask_inROI, [0 1]); 
        % 
        % figure;
        % imshow3Dfull(adc, [0 0.05]); 
        
        vessel = t1mask_inROI;
        mask = vessel;
                cd(CCDir);
                niftiwrite(t1mask_inROI, 'vessel_roi.nii');
        % 
        % 
        
        %%
                vessel = t1mask_inROI;
                
                for d = dilationDiameter;
                
                            %dilate the vessel
                            % dilatedVessel2remove = imdilate(vessel, strel('sphere',d-1));
                            dilatedVessel2remove = imdilate(vessel, strel('sphere', max(d-1, 1)));
                            dilatedVessel = imdilate(vessel, strel('sphere',d));
                
                            %Extract CSF only
                            CSFmask = (dilatedVessel-vessel-dilatedVessel2remove) .* ...
                                (b0Image>150);% apply ADC threshold here to use the same mask for ADC and FA
                            CSFmask(isnan(CSFmask)) = 0;
        
                            %%figure, imshow3Dfull([vessel+2*mask vessel+dilatedVessel])
                            %figure, imshow3Dfull([b0Image+4000.*mask b0Image+4000.*(vessel) b0Image+4000.*(dilatedVessel-vessel)  b0Image+4000.*CSFmask])
                            %figure, imshow3Dfull([b0Image+4000.*(vessel) b0Image+4000.*(dilatedVessel-vessel)  b0Image+4000.*CSFmask])
                            
                %             cd(CCDir);
                %             volumeToSave = single(CSFmask);
                %             diameter = num2str(d);
                %             niftiwrite(CSFmask, ['CSF_mask_' diameter '.nii']);
                % % 
                %             b0Vessel = b0Image+4000.*(vessel);
                %             niftiwrite(b0Vessel, ['b0vessel_' diameter '.nii']);
                % 
                %             b0Vessel = b0Image+4000.*(vessel);
                %             niftiwrite(b0Vessel, ['b0vessel_' diameter '.nii']);
        
                            % get CSF signal
                            CSF_masked = b0Image.* CSFmask;
                            averageCSF_MCA(k,d) = mean(nonzeros(CSF_masked(:)));
                            
                            % apply mask ADC
                            ADC_MCA_masked = adc.* CSFmask;
                            averageADC_MCA(k,d) = mean(nonzeros(ADC_MCA_masked(:)));
                            
                            
                            voxelNb(k,d) = sum(CSFmask(:));
                        clear dilatedVessel CSFmask
                end
        
        
        binCenters = (1:length(dilationDiameter(:))) * voxSize;
        % plotting 
        
         figure; hold on;
                    
                    yyaxis left
                    plot(binCenters, averageADC_MCA, 'b-', 'LineWidth',2);
                    ylabel('csf-mobility');
                    ylim([0.02 0.04]);
                    xlim([0.45 4]);
                    
                    yyaxis right
                    plot(binCenters, averageCSF_MCA, '-', 'LineWidth',2);
                    ylim([0 1000]);
                    ylabel(['non-motionsensitized scan']);
                    xlim([0.45 4]);
                    % ylabel('B0');   % if you want a right y-label
                    
                    xlabel('Dilation (mm)');
                    title(['CSF ' ROI ' ' subject_code]);
                    hold off;
               clear ADC_MCA ADC_MCA_masked mask tmp vessel b0Image
        end

cd(CCDir);

save(['allCSFmobilityLydiane' ROI '_Mean.mat'], 'averageADC_MCA');
save(['allB0Lydiane' ROI '_Mean.mat'], 'averageCSF_MCA');
%% plotting all subjects


 figure; hold on;
 meanADC = mean(averageADC_MCA);
            
            yyaxis left
            plot(binCenters, averageADC_MCA, '-', 'LineWidth', 1, 'Color', [0.2 0.4 1 0.2]);  % 4th value = alpha

            plot(binCenters, meanADC, 'b-', 'LineWidth',2);
            ylabel(['csf-mobility: ' ROI]);
            ylim([0 0.03]);
            xlim([0.45 6]);
            
            yyaxis right
            plot(binCenters, averageCSF_MCA, '-', 'LineWidth',2);
            ylim([0 1000]);
            ylabel(['non-motionsensitized scan:' ROI]);
            xlim([0.45 6]);
            % ylabel('B0');   % if you want a right y-label
            
            xlabel('Dilation (mm)');
            title(['CSF - Lydianes way - Mean' ROI])
            hold off;

end