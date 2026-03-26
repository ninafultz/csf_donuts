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



        % why are there NaNs?; why are the two concentric circles giving
        % such different results 
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


subject_list = {
    '20201111_Reconstruction'}



    % '20191022_Reconstruction' 
    % '20191112_Reconstruction' 
    % '20201020_Reconstruction'
    % '20201111_Reconstruction' 
    % '20191210_Reconstruction' 
    % '20201019_Reconstruction' 
    % '20201110_Reconstruction'}

allsubjectsADC = cell(1, numel(subject_list));

for k = 1:numel(subject_list)

    subject_code = subject_list{k};   % extract char vector / string

%% paths

subjPath                 = fullfile(project_directory, project_name, subject_code);
reorientedDir            = fullfile(subjPath, 'reoriented');
regDir                   = fullfile(subjPath, 'reg');
CCDir                   = fullfile(subjPath, '\', 'concentricCircles');
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

CSF = spm_vol('3dT1_0.9mm_CSF_to_B0_properOrientation.nii');
CSF_seg = spm_read_vols(CSF);

b0 = spm_vol('B0_from_mhd.nii');
b0_seg = spm_read_vols(b0);

b0 = spm_vol('B0_from_mhd_thr150.0000.nii');
b0_thresh = spm_read_vols(b0);


%% registration files, run in shark because of dependencies and path issues

%% show t1 and adc 
figure;
imshow3Dfull(t1); 

figure;
imshow3Dfull(adc, [0 0.05]);


%% thresholding t1 

if strcmp(subject_code, '20191022_Reconstruction')
        thresh = 200;
   elseif subject_code == "20191112_Reconstruction"
        thresh = 300000;
   elseif subject_code == "20201008_Reconstruction"
        thresh = 400000;
   elseif subject_code == "20201016_Reconstruction"
        thresh = 400000;
   elseif subject_code == "20201020_Reconstruction"
        thresh = 800;
   elseif subject_code == "20201111_Reconstruction"
        thresh = 800;
   elseif subject_code == "20191210_Reconstruction"
        thresh = 900;
   elseif subject_code == "20201019_Reconstruction"
        thresh = 1000;
   elseif subject_code == "20201110_Reconstruction"
        thresh = 1000;
end


t1_masked = t1;
t1_masked(t1 <= thresh) = 0; % im confused why you have to individually like threshold things?

figure;
imshow3Dfull(t1_masked);

%% seed growing on t1 
% sometimes you will have to play with the starting seed
% [198 338 189];

if subject_code == "20191022_Reconstruction"
    seed = [189 318 196];
elseif subject_code == "20191112_Reconstruction"
    seed = [242 333 174];
elseif subject_code == "20201008_Reconstruction"
    seed = [191 325 183];
elseif subject_code == "20201016_Reconstruction"
    seed = [235 313 226];
elseif subject_code == "20201020_Reconstruction"
    seed = [240 323 199];
elseif subject_code == "20201111_Reconstruction" % sometimes you will need two seeds because no connection between arteries; depends on shape
    seed = [
        193 321 175
        230 326 175
        ];
elseif subject_code == "20191210_Reconstruction"
    seed = [
        191 318 174
        236 313 174
        ];
elseif subject_code == "20201019_Reconstruction"
    seed = [
            189 318 187
            233 319 187
          ];
elseif subject_code == "20201110_Reconstruction"
    seed = [ 
        197 349 183
        237 347 183 
        ];
else
    error("Unknown subject: %s", subject)
end

t1_nonneg = t1_masked > 0;

seedMask = false(size(t1));
seedMask(sub2ind(size(t1), seed(:,1), seed(:,2), seed(:,3))) = true;

t1_nonneg = double(t1_nonneg);

vessel = imsegfmm(t1_nonneg, seedMask, 1);

figure;
imshow3Dfull(vessel);

    cd(CCDir);
    vesselsingle = single(vessel);
    volumeToSave = uint8(imbinarize(vesselsingle)); % 0/1 uint8
    niftiwrite(volumeToSave, 't1_vessel.nii');
%% plotting seed, making concentric circles
vars.t1       = t1;
vars.vessel   = vessel;
vars.adc      = adc;
vars.subjPath = subjPath;
vars.b0_thresh = b0_thresh;
vars.info = info;
vars.binWidth = binWidth;
vars.voxSize = voxSize;
vars.maxDist = maxDist;

%concentricCirclesv2(vars);


%% sanity check for shells

% 
% roiMask = vessel > 0;
% dist_mm = bwdist(roiMask) * voxSize;
% edges = 0:binWidth:maxDist;
% 
% nBins = numel(edges) - 1;
% meanADC = nan(nBins,1);
% stdADC = nan(nBins,1);
% nVoxels = zeros(nBins,1);
% allVals = cell(1, nBins);
% 
% 
% shellLabel = zeros(size(dist_mm));
% 
% for i = 1:nBins
%     mask = dist_mm >= edges(i) & dist_mm < edges(i+1) & ~roiMask;
%     shellLabel(mask) = i;
% end
% 
% 
% 
% 
% 
% for i = 1:nBins
%     binMask = dist_mm >= edges(i) & dist_mm < edges(i+1);
% 
%     % exclude seed ROI itself
%     mask = binMask & ~roiMask & adc>0;
% 
%     vals = adc(mask);
%     allVals{i} = vals;
%     if ~isempty(vals)
%         meanADC(i) = mean(double(vals));
%         stdADC(i)  = std(double(vals));
%         nVoxels(i) = nnz(mask);
%     end
% end
% 
% binCenters = edges(1:end-1) + binWidth/2;
% 
% upper = meanADC + stdADC;
% lower = meanADC - stdADC;
% 
% figure; hold on;
% fill([binCenters fliplr(binCenters)], ...
%      [upper' fliplr(lower')], ...
%      [0.8 0.8 0.8], 'EdgeColor','none', 'FaceAlpha',0.4);
% plot(binCenters, meanADC, 'k-', 'LineWidth',2);
% 
% xlabel('Dilation (mm)');
% ylabel('csf-mobility');
% xlim([0 maxDist]);
% ylim([0 0.005])
% hold off;
% 
% 
%         % Save as NIfTI - lol this is how you fix the itksnap problemo....
%         cd(CCDir);
%         niftiwrite(shellLabel, 'sheellLabel.nii');
% 
% 
% allsubjectsADC{k} = meanADC;
% cd(CCDir);
% save('meanCSFmobility_CC.mat', 'meanADC');
% 
close all;
clearvars -except project_directory project_name scripts ...
                  voxSize maxDist binWidth ...
                  subject_list allsubjectsADC subject_code

end


%% v2 cause something is up



for k = 1:numel(subject_list)

    subject_code = subject_list{k};   % extract char vector / string

%% paths

subjPath                 = fullfile(project_directory, project_name, subject_code);
reorientedDir            = fullfile(subjPath, 'reoriented');
regDir                   = fullfile(subjPath, 'reg');
ROISdir                  = fullfile(subjPath, 'ROIs');
CCDir                   = fullfile(subjPath, '\', 'concentricCircles');
mkdir(CCDir);
cd(reorientedDir);

%%
adcFile = 'masked_b0_ADC_mhd_thr150.0000.nii';
adcV = spm_vol(adcFile);
adc = spm_read_vols(adcV);
info = niftiinfo(adcFile);
%% sanity check for shells
cd(ROISdir);

V = spm_vol('circleShells_10_intersection_M1.nii');
circleLabelsMasked = spm_read_vols(V);

circleLabelsMasked = uint8(circleLabelsMasked);

nBins = double(max(circleLabelsMasked(:)));

meanADC = nan(nBins,1);
stdADC  = nan(nBins,1);
nVoxels = zeros(nBins,1);
allVals = cell(1,nBins);

for i = 1:nBins

    mask = (circleLabelsMasked == i);

    vals = adc(mask);

    allVals{i} = vals;

    if ~isempty(vals)
        meanADC(i) = mean(double(vals));
        stdADC(i)  = std(double(vals));
        nVoxels(i) = numel(vals);
    end
end

binCenters = (1:nBins) * binWidth;

upper = meanADC + stdADC;
lower = meanADC - stdADC;

figure; hold on;
fill([binCenters fliplr(binCenters)], ...
     [upper' fliplr(lower')], ...
     [0.8 0.8 0.8], 'EdgeColor','none', 'FaceAlpha',0.4);
plot(binCenters, meanADC, 'k-', 'LineWidth',2);
xlabel('Dilation (mm)');
ylabel('csf-mobility');
xlim([0 maxDist]);
%ylim([0 0.005])
hold off;

allsubjectsADC{k} = meanADC;
cd(CCDir);
save('meanCSFmobility_CC_final.mat', 'meanADC');

% close all;
clearvars -except project_directory project_name scripts ...
                  voxSize maxDist binWidth ...
                  subject_list allsubjectsADC subject_code

end



%% all subject plots across all concentric circles 

nSub = numel(subject_list);

allMeanADC = [];

for k = 1:nSub

    subj = subject_list{k};

    f = fullfile(project_directory, project_name, subj, ...
        '\concentricCircles\', 'meanCSFmobility_CC_final.mat');

    S = load(f,'meanADC');

    % stack as rows: subjects x bins
    allMeanADC(k,:) = S.meanADC(:).';

end

% group statistics
groupMean = mean(allMeanADC,1,'omitnan');
groupSEM  = std(allMeanADC,0,1,'omitnan') ./ sqrt(nSub);

upper = groupMean + groupSEM;
lower = groupMean - groupSEM;

edges = 0:binWidth:maxDist;
binCenters = edges(1:end-1);

figure; hold on

% uncertainty band
fill([binCenters fliplr(binCenters)], ...
     [upper fliplr(lower)], ...
     [0.8 0.8 0.8], ...
     'EdgeColor','none','FaceAlpha',0.4);

% individual subject curves
for k = 1:nSub
    plot(binCenters, allMeanADC(k,:), 'Color',[0.6 0.6 0.6]);
end

% group mean
plot(binCenters, groupMean, 'k-', 'LineWidth',2);

xlabel('Dilation (mm)');
ylabel('csf-mobility');
xlim([0 maxDist]);
%ylim([0 0.01]);

hold off

%%
nSub = numel(subject_list);

allMeanADC = [];

for k = 1:nSub

    subj = subject_list{k};

    f = fullfile(project_directory, project_name, subj, ...
        '\concentricCircles\', 'meanCSFmobility_CC_final.mat');

    S = load(f,'meanADC');

    % stack as rows: subjects x bins
    allMeanADC(k,:) = S.meanADC(:).';

end

% group statistics
groupMean = mean(allMeanADC,1,'omitnan');
groupSEM  = std(allMeanADC,0,1,'omitnan') ./ sqrt(nSub);

upper = groupMean + groupSEM;
lower = groupMean - groupSEM;

edges = 0:binWidth:maxDist;
binCenters = edges(1:end-1);

figure; hold on

% uncertainty band
fill([binCenters fliplr(binCenters)], ...
     [upper fliplr(lower)], ...
     [0.8 0.8 0.8], ...
     'EdgeColor','none','FaceAlpha',0.4);

% individual subject curves
for k = 1:nSub
    plot(binCenters, allMeanADC(k,:), 'Color',[0.6 0.6 0.6]);
end

% group mean
plot(binCenters, groupMean, 'k-', 'LineWidth',2);

xlabel('Dilation (mm)');
ylabel('csf-mobility');
xlim([0 maxDist]);
ylim([0 0.01]);

hold off



%%

binCenters = 0.45:0.45:10;

targets = [1 2 3 4 5];   % mm

meanADC_two = allMeanADC()
selADC = allMeanADC(:,idx);

groupMean = mean(selADC,1,'omitnan');

nPerBin  = sum(~isnan(selADC),1);
groupSEM = std(selADC,0,1,'omitnan') ./ sqrt(nPerBin);

upper = groupMean + groupSEM;
lower = groupMean - groupSEM;

x = 1:5;

figure; hold on

fill([x fliplr(x)], ...
     [upper fliplr(lower)], ...
     [0.8 0.8 0.8], ...
     'EdgeColor','none','FaceAlpha',0.4);

for k = 1:nSub
    plot(x, selADC(k,:), 'Color',[0.6 0.6 0.6]);
end

plot(x, groupMean, 'k-', 'LineWidth',2);

set(gca,'XTick',x, ...
    'XTickLabel',{'1 mm','2 mm','3 mm','1 mm after 3 mm','2 mm after 3 mm'});

xlim([0.5 5.5])
ylabel('CSF mobility')
hold off
