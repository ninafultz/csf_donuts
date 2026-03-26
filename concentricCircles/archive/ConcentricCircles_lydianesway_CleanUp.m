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

ROIs = {'M2'};

subject_list = {
    '20201110_Reconstruction' 
}

dilationDiameter = [1:10];

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
        
   for r = 1:numel(ROIs);
        ROI = ROIs{r};
        cd(ROIsDir);
        V = spm_vol(['parsing' ROI '.nii']);
        vesselmask = spm_read_vols(V);
        
        cd(reorientedDir);
        t1vessel = spm_vol('t1_vessel.nii');
        t1vesselmask = spm_read_vols(t1vessel);
        
        t1mask_inROI = t1vesselmask .* (vesselmask > 0) .* (adc == 0);

        % figure;
        % imshow3Dfull(t1mask_inROI); 
        vessel = t1mask_inROI;
        mask = vessel;

        
        %%
                vessel = t1mask_inROI;

                dilatedMask = logical(t1mask_inROI);
                adcMask = logical(adc > 0);
                adcZeroMask = logical(adc == 0);

                se = strel('sphere', 1);



                vessel      = logical(t1mask_inROI);
                csfSpace    = logical(b0Image > 150);  % the only space we're allowed to grow into
                dilatedMask = vessel;
                
                se = strel('sphere', 1);
                
                for iter = 1:10
                    expanded = imdilate(dilatedMask, se);
                    
                    % Only grow into real CSF voxels — this prevents bleeding into empty space
                    newVoxels = expanded & ~dilatedMask & csfSpace;
                    
                    if ~any(newVoxels, 'all')
                        break  % mask has reached all reachable CSF — stop
                    end
                    
                    dilatedMask = dilatedMask | newVoxels;
                end
                
                boundarySingle = single(dilatedMask);
                

                cd(CCDir);
                niftiwrite(boundarySingle, 'vessel_roi_noOverlap_adcBoundary_round4.nii');

                for d = dilationDiameter;
                
                            %dilate the vessel
                           dilatedVessel2remove = imdilate(boundarySingle, strel('sphere',d-1));
                            % dilatedVessel2remove = imdilate(vessel, strel('sphere', max(d-1, 1)));
                           % dilatedVessel = imdilate(vessel, strel('sphere',d));
                
                            dilatedVessel = imdilate(boundarySingle, strel('sphere', d));

                            if d ==1; 
                                     CSFmask = (dilatedVessel-vessel).* ...
                                     (b0Image>150);
                            else
%%   
                                %Extract CSF only
                                 CSFmask = (dilatedVessel-vessel-dilatedVessel2remove).* ...
                                 (b0Image>150);
                            end

                            cd(CCDir);
                            volumeToSave = single(CSFmask);
                            diameter = num2str(d);
                            niftiwrite(CSFmask, ['CSF_mask_' diameter ' ' ROI '.nii']);

                            % get CSF signal
                            CSF_masked = b0Image.* CSFmask;
                            averageCSF_MCA(k,d) = median(nonzeros(CSF_masked(:)));
                            
                            % apply mask ADC
                            ADC_MCA_masked = adc.* CSFmask;
                            averageADC_MCA(k,d) = median(nonzeros(ADC_MCA_masked(:)));
                            
                            
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
                    title(['CSF ' ROI])
                    hold off;
               clear ADC_MCA ADC_MCA_masked mask tmp vessel b0Image
        end

cd(CCDir);

save(['allCSFmobilityLydiane' ROI '_MedianFeb23rd.mat'], 'averageADC_MCA');
save(['allB0Lydiane' ROI '_MedianFeb23rd.mat'], 'averageCSF_MCA');
%% plotting all subjects


 figure; hold on;
 meanADC = mean(averageADC_MCA);
            
            yyaxis left
            plot(binCenters, averageADC_MCA, '-', 'LineWidth', 1, 'Color', [0.2 0.4 1 0.2]);  % 4th value = alpha

            plot(binCenters, meanADC, 'b-', 'LineWidth',2);
            ylabel(['csf-mobility: ' ROI]);
            ylim([0 0.04]);
            xlim([0.45 4]);
            
            yyaxis right
            plot(binCenters, averageCSF_MCA, '-', 'LineWidth',2);
            ylim([0 1000]);
            ylabel(['non-motionsensitized scan:' ROI]);
            xlim([0 4]);
            % ylabel('B0');   % if you want a right y-label
            
            xlabel('Dilation (mm)');
            title(['CSF - Lydianes way ' ROI])
            hold off;

end