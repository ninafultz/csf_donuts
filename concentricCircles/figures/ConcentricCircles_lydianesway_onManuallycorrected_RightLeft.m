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

ROI = 'M2';
sides = {'left', 'right', 'both'};

subject_list = {
     '20191112_Reconstruction'
     '20201008_Reconstruction'
     '20201016_Reconstruction'
     '20191029_Rec'
     '20201014_Reconstruction'
    '20191022_Reconstruction'
    '20201020_Reconstruction'
    '20201111_Reconstruction'
    '20191210_Reconstruction'
    '20201019_Reconstruction'
    '20201110_Reconstruction'};


dilationDiameter = [1:10];

for r = 1:numel(sides);
side = sides{r};
        for k = 1:numel(subject_list)
        
        subject_code = subject_list{k}
        %% paths
        
        subjPath                 = fullfile(project_directory, project_name, subject_code);
        CCResults                = fullfile(project_directory, project_name, 'concentricCircleResults');
        addpath(CCResults);

        reorientedDir            = fullfile(subjPath, 'reoriented');
        regDir                   = fullfile(subjPath, 'reg');
        CCDir                   = fullfile(subjPath, '\', 'concentric_Circles');
        mkdir(CCDir);
        MRScriptsDir             = fullfile(scripts, 'mr_analysis');
        addpath(genpath(fullfile(project_directory, project_name, subject_code)));
        
        %% loading t1, csf mobility 
        
   % Default filenames
                    t1File = 't1.nii'; % rT1
                    adcFile = 'csf_mobility.nii';
                    b0File  = 'b0.nii';

                    % Load volumes
                     cd(CCDir);
                    V   = spm_vol(t1File);      % USE BIASFIELD CORRECTED SCAN
                    t1  = spm_read_vols(V);
                    
                    adcV = spm_vol(adcFile);
                    adc  = spm_read_vols(adcV);
                    info = niftiinfo(adcFile);
                    
                    b0   = spm_vol(b0File);
                    b0Image = spm_read_vols(b0);

                    if strcmp(side, 'right') || strcmp(side, 'left')
                        vessel_file = fullfile(CCDir, ['vesselKept_' ROI '_' side '.nii']);
                    else
                        vessel_file = fullfile(CCDir, ['vesselKept_' ROI '.nii']);
                    end
                    
                    if exist(vessel_file, 'file')
                        V      = spm_vol(vessel_file);
                        vessel = spm_read_vols(V);
                    end

                   
        
        %%

                for d = dilationDiameter;

                            %dilate the vessel
                           dilatedVessel2remove = imdilate(vessel, strel('sphere',d-1));
                            % dilatedVessel2remove = imdilate(vessel, strel('sphere', max(d-1, 1)));
                           % dilatedVessel = imdilate(vessel, strel('sphere',d));

                            dilatedVessel = imdilate(vessel, strel('sphere', d));

                            if d == 1; 
                                     CSFmask = (dilatedVessel-vessel).* ...
                                     (b0Image>150);
                            else
%%   
                                %Extract CSF only
                                 CSFmask = (dilatedVessel-vessel-dilatedVessel2remove).* ...
                                 (b0Image>150);
                            end
                            % CSFmask = (dilatedVessel-vessel-dilatedVessel2remove) .* ...
                            %     (b0Image>150);% apply ADC threshold here to use the same mask for ADC and FA
                           % CSFmask(isnan(CSFmask)) = 0;

                            %%figure, imshow3Dfull([vessel+2*mask vessel+dilatedVessel])
                            %figure, imshow3Dfull([b0Image+4000.*mask b0Image+4000.*(vessel) b0Image+4000.*(dilatedVessel-vessel)  b0Image+4000.*CSFmask])
                            %figure, imshow3Dfull([b0Image+4000.*(vessel) b0Image+4000.*(dilatedVessel-vessel)  b0Image+4000.*CSFmask])

                            cd(CCDir);
                            volumeToSave = single(CSFmask);
                            diameter = num2str(d);
                            niftiwrite(CSFmask, ['CSFMask_' diameter '_' ROI '_' side '.nii']);

                            % get CSF signal
                            CSF_masked = b0Image.* CSFmask;
                            averageCSF_MCA(k,d) = median(nonzeros(CSF_masked(:)));
                            averageCSF_MCA_Mean(k,d) = mean(nonzeros(CSF_masked(:)));

                            % apply mask ADC
                            ADC_MCA_masked = adc.* CSFmask;
                            averageADC_MCA(k,d) = median(nonzeros(ADC_MCA_masked(:)));
                            averageADC_MCA_Mean(k,d) = mean(nonzeros(ADC_MCA_masked(:)));

                            voxelNb(k,d) = sum(CSFmask(:));
                        clear dilatedVessel CSFmask
                end
        end

      
cd(CCResults);

% median 
save(['allCSFmobilityLydiane' ROI '_Median_' side '.mat'], 'averageADC_MCA');
save(['allB0Lydiane' ROI '_Median_' side '.mat'], 'averageCSF_MCA');

% mean
save(['allCSFmobilityLydiane' ROI '_Mean_' side '.mat'], 'averageADC_MCA_Mean');
save(['allB0Lydiane' ROI '_Mean_' side '.mat'], 'averageCSF_MCA_Mean');
%% plotting all subjects
binCenters = (0:length(dilationDiameter(:))-1) * voxSize;

 figure; hold on;
 meanADC = mean(averageADC_MCA);
            
    yyaxis left
    plot(binCenters, averageADC_MCA, '-', 'LineWidth', 1, 'Color', [0.2 0.4 1 0.2]);  % 4th value = alpha
    
    plot(binCenters, meanADC, 'b-', 'LineWidth',2);
    ylabel(['csf-mobility: ' ROI]);
    ylim([0 0.04]);
    xlim([0 4]);
    
    yyaxis right
    plot(binCenters, averageCSF_MCA, '-', 'LineWidth',2);
    ylim([0 1000]);
    ylabel(['non-motionsensitized scan:' ROI]);
    xlim([0 4]);
    % ylabel('B0');   % if you want a right y-label
    
    xlabel('Dilation (mm)');
    title(['CSF - Lydianes way - All Subjects - Median ' ROI ' ' side])
    hold off;


             figure; hold on;
             meanADC = mean(averageADC_MCA_Mean);
            
            yyaxis left
            plot(binCenters, averageADC_MCA_Mean, '-', 'LineWidth', 1, 'Color', [0.2 0.4 1 0.2]);  % 4th value = alpha

            plot(binCenters, meanADC, 'b-', 'LineWidth',2);
            ylabel(['csf-mobility: ' ROI]);
            ylim([0 0.04]);
            xlim([0 4]);
            
            yyaxis right
            plot(binCenters, averageCSF_MCA_Mean, '-', 'LineWidth',2);
            ylim([0 1000]);
            ylabel(['non-motionsensitized scan:' ROI]);
            xlim([0 4]);
            % ylabel('B0');   % if you want a right y-label
            
            xlabel('Dilation (mm)');
            title(['CSF - Lydianes way - All Subjects - Mean ' ROI ' ' side])
            hold off;
           
            clear ADC_MCA ADC_MCA_masked mask tmp vessel b0Image
                           
                            clear averageCSF_MCA;
                            clear averageCSF_MCA_Mean;
                            clear averageADC_MCA;
                            clear averageADC_MCA_Mean;

end