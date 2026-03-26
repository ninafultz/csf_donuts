% csf donut protocol for CAA patients 
% nina fultz january 2026
% n.e.fultz@lumc.nl
% on practice subject.... 

%%
% to do:
    % making it so that the concentric circles now expand to where adc is zero, 
    % and that if the t1 overlaps with a positive csf value, then that gets
    % excluded. 

    % make it so that the vessel mask is better and in the right region --
    % still a bit too broad; not completely sure this is in the right spot
    % now
    % mask into regions - separating m1 vs. m2 - regional flow territories 
    
% Stripe check to make chunks 
% Correct for the t1 and CSF 
% Region growing on blood
% do m1, ica, etc

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
subject_code      = '20201020_Reconstruction'

scripts           = fullfile(project_directory, 'scripts', project_name);
addpath(genpath(fullfile(scripts, 'csfdonuts_lydiane')));
addpath(genpath(fullfile(scripts, 'toolbox', 'nifti_tools-master')));
addpath(genpath(fullfile(scripts, 'toolbox', 'elastix-5.2.0-linux')));
addpath(genpath(fullfile(scripts, 'toolbox')));
addpath(genpath(fullfile(scripts, 'dcm2niix')));
addpath(genpath(fullfile(scripts)));
addpath(genpath(fullfile(project_directory, project_name, subject_code)));


%% paths

subjPath                 = fullfile(project_directory, project_name, subject_code);
reorientedDir            = fullfile(subjPath, 'reoriented');
cd(reorientedDir);

%% loading t1, csf mobility 

V = spm_vol('3dT1_0.9mm_to_B0_properOrientation.nii'); % USE BIASFIELD CORRECTED SCAN
t1 = spm_read_vols(V);

adcFile = 'masked_b0_ADC_mhd_thr150.0000.nii';
adcV = spm_vol(adcFile);
adc = spm_read_vols(adcV);
info = niftiinfo(adcFile);

seg = spm_vol('3dT1_0.9mm_to_B0_properOrientation_segmented.nii');
t1_seg = spm_read_vols(seg);

CSF = spm_vol('3dT1_0.9mm_CSF_to_B0_properOrientation.nii');
CSF_seg = spm_read_vols(CSF);

b0 = spm_vol('B0_from_mhd.nii');
b0_seg = spm_read_vols(b0);

b0 = spm_vol('B0_from_mhd_thr150.0000.nii');
b0_thresh = spm_read_vols(b0);

WM = spm_vol('3dT1_0.9mm_WM_to_B0_properOrientation.nii');
wm = spm_read_vols(WM);

GM = spm_vol('3dT1_0.9mm_GM_to_B0_properOrientation.nii');
gm = spm_read_vols(GM);
%% show t1 and adc 
figure;
imshow3Dfull(t1); 

figure;
imshow3Dfull(adc, [0 0.05]);

figure;
imshow3Dfull(t1_seg); 

figure;
imshow3Dfull(CSF_seg); 

%% thresholding t1 
GMWM_mask = logical(wm);
t1(GMWM_mask) = 0;

t1_masked = t1 > 500;   % example threshold

figure;
imshow3Dfull(t1_masked); 


%% seed growing on t1 
seed = [198 338 189];
t1_nonneg = t1_masked > 0;
seedMask = false(size(t1));
seedMask(seed(1), seed(2), seed(3)) = true;
seedMask = logical(seedMask);
t1_nonneg = double(t1_nonneg);
vessel = imsegfmm(t1_nonneg, seedMask, 0.3);  

figure;
imshow3Dfull(vessel)


%% plotting to look at seed

T = mat2gray(t1);
M = vessel;

rgb = zeros([size(T) 3]);
rgb(:,:,:,1) = T;          % R
rgb(:,:,:,2) = T;          % G
rgb(:,:,:,3) = T;          % B

rgb(:,:,:,1) = rgb(:,:,:,1) + 0.8*M;  % red overlay

rgb(rgb > 1) = 1;

figure;
imshow3Dfull(rgb);


%% plotting over the adc map 
T = mat2gray(adc);
% Window limits
Tmin = 0;
Tmax = 0.05;

% Clip
Tdisp = T;
Tdisp(Tdisp < Tmin) = Tmin;
Tdisp(Tdisp > Tmax) = Tmax;

% Normalize to [0, 1] for display
Tdisp = (Tdisp - Tmin) / (Tmax - Tmin);
M = vessel;

rgb = zeros([size(Tdisp) 3]);
rgb(:,:,:,1) = Tdisp;          % R
rgb(:,:,:,2) = Tdisp;          % G
rgb(:,:,:,3) = Tdisp;          % B

rgb(:,:,:,1) = rgb(:,:,:,1) + 0.8*M;  % red overlay

rgb(rgb > 1) = 1;

figure;
imshow3Dfull(rgb);

%% saving

vesselsingle = single(vessel);
volumeToSave = imbinarize(vesselsingle);
% volumeToSave = single(vessel);
niftiwrite(volumeToSave, 't1_vesselv2.nii');

vesselsingle = single(vessel);
volumeToSave = uint8(imbinarize(vesselsingle)); % 0/1 uint8
niftiwrite(volumeToSave, 't1_vesselv2.nii');

%% stepping down and plotting 

meanADC = nan(nShells,1);
nVoxels = zeros(nShells,1);
stdADC = nan(nShells,1);

for i = 1:nShells
    mask = (circleLabelsMasked == i);
    vals = adc(mask);
    stdADC(i) = std(vals, 'omitnan'); 
    meanADC(i) = mean(vals, 'omitnan');
    nVoxels(i) = nnz(mask);
end

% Create shaded region
upper = meanADC + stdADC;
lower = meanADC - stdADC;

figure;
hold on;
x = 1:nShells;

% Fill the shaded area
fill([x fliplr(x)], [upper' fliplr(lower')], ...
     [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

% Plot the mean line
plot(x, meanADC, '-b', 'LineWidth', 2, 'Marker', 'o');

xlabel('Shell index (distance from seed)');
ylabel('ADC value');
title('Mean ADC ± SD per concentric shell (shaded)');
grid on;
hold off;



%% loading just post m1 concentric circles:
roi = spm_vol('circleShells_10.nii');
circleLabelsMasked = spm_read_vols(roi);

roiparsed = spm_vol('circleShells_10_postm1.nii');
roi_small = spm_read_vols(roiparsed);

meanADC = nan(nShells,1);
nVoxels = zeros(nShells,1);
stdADC = nan(nShells,1);

for i = 1:nShells
    mask = (circleLabelsMasked == i);
    vals = adc(mask);
    stdADC(i) = std(vals, 'omitnan'); 
    meanADC(i) = mean(vals, 'omitnan');
    nVoxels(i) = nnz(mask);
end

% Create shaded region
upper = meanADC + stdADC;
lower = meanADC - stdADC;

figure;
hold on;
x = 1:nShells;

% Fill the shaded area
fill([x fliplr(x)], [upper' fliplr(lower')], ...
     [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

% Plot the mean line
plot(x, meanADC, '-b', 'LineWidth', 2, 'Marker', 'o');

xlabel('Shell index (distance from seed)');
ylabel('ADC value');
title('Mean ADC ± SD per concentric shell (shaded)');
grid on;
hold off;


%%

roi = spm_vol('circleShells_10.nii');
circleLabelsMasked = spm_read_vols(roi);

roiparsed = spm_vol('circleShells_10_m1.nii');
roi_small = spm_read_vols(roiparsed);
roiMask = roi_small > 0;

meanADC = nan(nShells,1);
nVoxels = zeros(nShells,1);
stdADC = nan(nShells,1);

nShells = max(circleLabelsMasked(:));

meanADC = nan(nShells,1);
stdADC  = nan(nShells,1);
nVoxels = zeros(nShells,1);

for i = 1:nShells
    shellMask = (circleLabelsMasked == i);

    % apply ROI
    mask = shellMask & roiMask;

    vals = adc(mask);

    if ~isempty(vals)
        meanADC(i) = mean(double(vals));
        stdADC(i)  = std(double(vals));
        nVoxels(i) = nnz(mask);
    end
end

% Create shaded region
upper = meanADC + stdADC;
lower = meanADC - stdADC;

figure;
hold on;
x = 1:nShells;

% Fill the shaded area
fill([x fliplr(x)], [upper' fliplr(lower')], ...
     [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.3);

% Plot the mean line
plot(x, meanADC, '-b', 'LineWidth', 2, 'Marker', 'o');

xlabel('Shell index (distance from seed)');
ylabel('ADC value');
title('Mean ADC ± SD per concentric shell (shaded)');
xlim([1 10])
xticks(1:10)
grid on;
hold off;

niftiwrite(uint8(vessel), 'vessel_mask.nii');

%%
roi = spm_vol('circleShells_10.nii');
circleLabelsMasked = spm_read_vols(roi);

roi = spm_vol('vessel_mask_m1.nii');
vessel = spm_read_vols(roi);

roiMask = vessel > 0;

voxSize = 0.45; % mm
dist_mm = bwdist(roiMask) * voxSize;

maxDist = 4.5; % mm
binWidth = 0.45; % mm
edges = 0:binWidth:maxDist;


nBins = numel(edges) - 1;
meanADC = nan(nBins,1);
stdADC = nan(nBins,1);
nVoxels = zeros(nBins,1);

for i = 1:nBins
    binMask = dist_mm >= edges(i) & dist_mm < edges(i+1);

    % exclude seed ROI itself
    mask = binMask & ~roiMask;

    vals = adc(mask);

    if ~isempty(vals)
        meanADC(i) = mean(double(vals));
        stdADC(i)  = std(double(vals));
        nVoxels(i) = nnz(mask);
    end
end

binCenters = edges(1:end-1) + binWidth/2;

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
ylim([0 0.04])
hold off;


%% 
% still need to check that we arent collecting zeros in the t1 adc cut offs

roi = spm_vol('circleShells_10.nii');
circleLabelsMasked = spm_read_vols(roi);

roi = spm_vol('vessel_mask_postm1.nii');
vessel = spm_read_vols(roi);

roiMask = vessel > 0;

voxSize = 0.45; % mm
dist_mm = bwdist(roiMask) * voxSize;

maxDist = 6; % mm
binWidth = 0.45; % mm
edges = 0:binWidth:maxDist;


nBins = numel(edges) - 1;
meanADC = nan(nBins,1);
stdADC = nan(nBins,1);
nVoxels = zeros(nBins,1);

for i = 1:nBins
    binMask = dist_mm >= edges(i) & dist_mm < edges(i+1);

    % exclude seed ROI itself
    mask = binMask & ~roiMask;

    vals = adc(mask);

    if ~isempty(vals)
        meanADC(i) = mean(double(vals));
        stdADC(i)  = std(double(vals));
        nVoxels(i) = nnz(mask);
    end
end

binCenters = edges(1:end-1) + binWidth/2;

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
ylim([0 0.04])
hold off;


%% calculating how much area the high mobility takes up in general with 0.02 cut off

% Load vessel mask
Vv = spm_vol('vessel_mask_postm1.nii');
vessel = spm_read_vols(Vv) > 0;

% Load signal image (replace with your actual image)

signal = adc;

% Voxel size (mm)
voxSize = 0.45;

% Distance map from vessel seed
dist_mm = bwdist(vessel) * voxSize;

% Define maximum distance: 10 shells
maxShells = 10;
maxDist = maxShells * voxSize; % 4.5 mm

withinDistMask = dist_mm <= maxDist;

% Signal threshold mask
signalMask = signal >= 0.02;

% Final ROI: signal + distance constraint
finalMask = withinDistMask & signalMask;

% Compute area
voxelArea_mm3 = voxSize^3;   % assuming 3D
area_mm3 = sum(finalMask(:)) * voxelArea_mm3;



% Create RGB volume
rgbVol = repmat(Tdisp, [1 1 1 3]);

% Overlay parameters
alpha = 0.9;
overlayColor = [1 0 0]; % red

mask = finalMask > 0;

for c = 1:3
    rgbVol(:,:,:,c) = rgbVol(:,:,:,c) .* (~mask) + ...
                      ((1 - alpha) * rgbVol(:,:,:,c) + alpha * overlayColor(c)) .* mask;
end

% Display
figure;
imshow3Dfull(rgbVol);


%% calculating how much area the high mobility takes up in general with 20% drop

% Load vessel mask
Vv = spm_vol('vessel_mask_postm1.nii');
vessel = spm_read_vols(Vv) > 0;

% Load signal image (replace with your actual image)

signal = adc;

% Voxel size (mm)
voxSize = 0.45;

% Distance map from vessel seed
dist_mm = bwdist(vessel) * voxSize;

% Define maximum distance: 10 shells
maxShells = 10;
maxDist = maxShells * voxSize; % 4.5 mm

withinDistMask = dist_mm <= maxDist;

% Signal threshold mask
signalMask = signal >= 0.02;

% Final ROI: signal + distance constraint
finalMask = withinDistMask & signalMask;

% Compute area
voxelArea_mm3 = voxSize^3;   % assuming 3D
area_mm3 = sum(finalMask(:)) * voxelArea_mm3;



% Create RGB volume
rgbVol = repmat(Tdisp, [1 1 1 3]);

% Overlay parameters
alpha = 0.9;
overlayColor = [1 0 0]; % red

mask = finalMask > 0;

for c = 1:3
    rgbVol(:,:,:,c) = rgbVol(:,:,:,c) .* (~mask) + ...
                      ((1 - alpha) * rgbVol(:,:,:,c) + alpha * overlayColor(c)) .* mask;
end

% Display
figure;
imshow3Dfull(rgbVol);

%% 20% drop condition with fill

sz = size(adc);

seed = [193 323 206];  
visited = false(sz);
grownMask = false(sz);

% 6-connected neighbors
nbrs = [ ...
     1  0  0;
    -1  0  0;
     0  1  0;
     0 -1  0;
     0  0  1;
     0  0 -1];

% queue for region growing
Q = seed;
grownMask(seed(1),seed(2),seed(3)) = true;
visited(seed(1),seed(2),seed(3)) = true;

while ~isempty(Q)
    v = Q(1,:); 
    Q(1,:) = [];

    vVal = adc(v(1),v(2),v(3));

    for k = 1:6
        n = v + nbrs(k,:);
        if any(n < 1) || n(1) > sz(1) || n(2) > sz(2) || n(3) > sz(3)
            continue
        end
        if visited(n(1),n(2),n(3))
            continue
        end

        nVal = adc(n(1),n(2),n(3));

        % local 20% decrease rule
        if nVal >= 0.8 * vVal
            grownMask(n(1),n(2),n(3)) = true;
            Q(end+1,:) = n; %
        end

        visited(n(1),n(2),n(3)) = true;
    end
end

grownMaskCut = grownMask(:,:,200:end);

figure;
imshow3Dfull(grownMaskCut); 

grownMaskFilled = imclose(grownMaskCut, ones(3,3,3)); 
threshold = 0;

% Remove voxels in grownMaskFilled where ADC is zero
grownMaskFilled(adc(:,:,200:end) == 0) = 0;

figure;
imshow3Dfull(grownMaskCut); 

% Normalize ADC to [0,1] for display
adcNorm = adc(:,:,200:end);
adcNorm(adcNorm < 0) = 0;  % clamp below 0
adcNorm(adcNorm > 0.1) = 0.1;  % clamp above 0.05
adcNorm = adcNorm / 0.1;  % scale to 0–1

% Create RGB volume
rgbVol = repmat(adcNorm, [1 1 1 3]); % grayscale as starting point

% Overlay mask in red
rgbVol(:,:,:,1) = rgbVol(:,:,:,1) + 0.6 * grownMaskFilled;  % red channel
rgbVol(:,:,:,2) = rgbVol(:,:,:,2) .* (1 - 0.6*grownMaskFilled);  % green channel suppressed
rgbVol(:,:,:,3) = rgbVol(:,:,:,3) .* (1 - 0.6*grownMaskFilled);  % blue channel suppressed

% Clip to [0,1]
% rgbVol(rgbVol>1) = 1;

% Visualize
figure;
imshow3Dfull(rgbVol);



%% 0.02 cut off
sz = size(adc);

seed = [193 323 206];  
visited = false(sz);
grownMask = false(sz);

% 6-connected neighbors
nbrs = [ ...
     1  0  0;
    -1  0  0;
     0  1  0;
     0 -1  0;
     0  0  1;
     0  0 -1];

% Queue for region growing
Q = seed;
grownMask(seed(1),seed(2),seed(3)) = true;
visited(seed(1),seed(2),seed(3)) = true;

minADC = 0.02;   % absolute threshold

while ~isempty(Q)
    v = Q(1,:); 
    Q(1,:) = [];

    for k = 1:6
        n = v + nbrs(k,:);
        if any(n < 1) || n(1) > sz(1) || n(2) > sz(2) || n(3) > sz(3)
            continue
        end
        if visited(n(1),n(2),n(3))
            continue
        end

        % Include if above threshold
        if adc(n(1),n(2),n(3)) >= minADC
            grownMask(n(1),n(2),n(3)) = true;
            Q(end+1,:) = n; 
        end

        visited(n(1),n(2),n(3)) = true;
    end
end

% Optional cropping
grownMaskCut = grownMask(:,:,200:end);

% Fill small holes
grownMaskFilled = imclose(grownMaskCut, ones(3,3,3));

% Remove voxels below threshold in ADC
grownMaskFilled(adc(:,:,200:end) < minADC) = 0;

% Normalize ADC for display
adcNormless = adcNorm(:,:,200:end);

% Create RGB volume
rgbVol = repmat(adcNorm, [1 1 1 3]);
alpha = 0.8;

% Overlay mask in red
rgbVol(:,:,:,1) = rgbVol(:,:,:,1) + alpha * grownMaskFilled;
rgbVol(:,:,:,2) = rgbVol(:,:,:,2) .* (~grownMaskFilled + (1-alpha)*grownMaskFilled);
rgbVol(:,:,:,3) = rgbVol(:,:,:,3) .* (~grownMaskFilled + (1-alpha)*grownMaskFilled);


% Display
figure;
imshow3Dfull(rgbVol);


%% concentric circles but only at intersection 
% gotta figure out bwdist?????

threshold = 0;
adcSignal = b0_thresh >= threshold;

% removing any vessel seg where there is b0 > 0
vessel(b0_thresh > 0) = 0;

vesselSeed = vessel & adcSignal;

% Label seeds
seedLabels = bwlabeln(vesselSeed, 26);

% Distance + nearest seed
[distMap, nearestSeed] = bwdist(vesselSeed);

% Mask invalid ADC
distMap(~adcSignal) = Inf;
nearestSeed(~adcSignal) = 0;


radii = 0.45:0.45:10;
circleLabels = zeros(size(adc), 'uint8');

for i = 1:numel(radii)
    if i == 1
        mask = distMap < radii(i);
    else
        mask = distMap >= radii(i-1) & distMap < radii(i);
    end

    % Assign only inside a single seed’s territory
    circleLabels(mask & nearestSeed & adc > 0) = i;
end

circleLabelsMasked = circleLabels;
%circleLabelsMasked(adc == 0) = 0;  % remove any circles outside ADC signal


% Create RGB volume
rgbVol = repmat(adc, [1 1 1 3]);  % grayscale base

% Map labels to rainbow
nShells = max(circleLabelsMasked(:));
cmap = hsv(double(nShells));

alpha = 0.9;  % transparency for overlay

% Overlay each shell
for i = 1:nShells
    mask = (circleLabelsMasked == i);  % current shell
    for c = 1:3
        rgbVol(:,:,:,c) = rgbVol(:,:,:,c) .* (~mask) + ...
                           (1 - alpha) * rgbVol(:,:,:,c) + alpha * cmap(i,c) * mask;
    end
end

% Display
figure;
imshow3Dfull(rgbVol);

% saving concentric circles as niftis
nShells = max(circleLabelsMasked(:));
mkdir([subjPath, 'concentric_circles']);

% Convert circleLabelsMasked to match reference datatype
switch info.Datatype
    case 'uint8'
        volumeToSave = uint8(circleLabelsMasked);
    case 'int16'
        volumeToSave = int16(circleLabelsMasked);
    case 'single'
        volumeToSave = single(circleLabelsMasked);
    case 'double'
        volumeToSave = double(circleLabelsMasked);
    otherwise
        error('Unsupported datatype in reference NIfTI.');
end


% Save as NIfTI - lol this is how you fix the itksnap problemo....
cd([subjPath, '\' 'ROIs']);
niftiwrite(volumeToSave, 'circleShells_10_intersection.nii');

% saving concentric circles as niftis
nShells = max(circleLabelsMasked(:));
mkdir([subjPath, 'concentric_circles']);

% Convert circleLabelsMasked to match reference datatype
switch info.Datatype
    case 'uint8'
        volumeToSave = uint8(circleLabelsMasked);
    case 'int16'
        volumeToSave = int16(circleLabelsMasked);
    case 'single'
        volumeToSave = single(circleLabelsMasked);
    case 'double'
        volumeToSave = double(circleLabelsMasked);
    otherwise
        error('Unsupported datatype in reference NIfTI.');
end


% Save as NIfTI - lol this is how you fix the itksnap problemo....
cd([subjPath, '\' 'ROIs']);
niftiwrite(volumeToSave, 'circleShells_10.nii');

volumeToSave = single(adc);
niftiwrite(volumeToSave, 'adc_circleShells.nii');

volumeToSave = single(t1);
niftiwrite(volumeToSave, 't1_circleShells.nii');

volumeToSave = single(b0_thresh);
niftiwrite(volumeToSave, 'b0thresh_circleShells.nii');
