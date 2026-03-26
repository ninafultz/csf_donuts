% csf donut protocol for CAA patients 
% nina fultz january 2026
% n.e.fultz@lumc.nl


%% output: mask of vasculature tree 
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


subject_code = '20191112_Reconstruction'; 
    % '20191112_Reconstruction'
    % '20201016_Reconstruction'
    % '20191029_Rec'
    % '20201014_Reconstruction'}

    % '20191022_Reconstruction' 
    % '20191112_Reconstruction' 
    % '20201020_Reconstruction'
    % '20201111_Reconstruction' 
    % '20191210_Reconstruction' 
    % '20201019_Reconstruction' 
    % '20201110_Reconstruction'}

% allsubjectsADC = cell(1, numel(subject_list));
% subject_code = subject_list{k};   % extract char vector / string

%% paths

subjPath                 = fullfile(project_directory, project_name, subject_code);
reorientedDir            = fullfile(subjPath, 'reoriented');
regDir                   = fullfile(subjPath, 'reg');
CCDir                   = fullfile(subjPath, '\', 'makingVessels');
mkdir(CCDir);
cd(reorientedDir);
MRScriptsDir             = fullfile(scripts, 'mr_analysis');
addpath(genpath(fullfile(project_directory, project_name, subject_code)));

%% loading t1, csf mobility 


% Default filenames
t1File  = '3dT1_0.9mm_to_B0_properOrientation.nii';
adcFile = 'masked_b0_ADC_mhd_thr150.0000.nii';
b0File  = 'B0_from_mhd.nii';


switch subject_code
    case '20191112_Reconstruction'
        t1File = 't1_moving_registered.nii.gz';

    case {'20201008_Reconstruction', '20201016_Reconstruction', '20201014_Reconstruction'}
        t1File = 'r3dT1_0.9mm_to_B0_properOrientation.nii'; % rT1

    case '20191029_Rec'
        t1File  = '3dT1_ITKSNAP.nii';
        adcFile = 'ADC_ITKSNAP.nii';
end

% Load volumes
V   = spm_vol(t1File);      % USE BIASFIELD CORRECTED SCAN
t1  = spm_read_vols(V);

adcV = spm_vol(adcFile);
adc  = spm_read_vols(adcV);
info = niftiinfo(adcFile);

b0   = spm_vol(b0File);
b0_seg = spm_read_vols(b0);

%% registration files, run in shark because of dependencies and path issues

%% show t1 and adc 
figure;
imshow3Dfull(t1); 

figure;
imshow3Dfull(adc, [0 0.05]);


%% thresholding t1: manually look at output 

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
   elseif subject_code == "20191029_Rec"
        thresh = 200;
   elseif subject_code == "20201014_Reconstruction"
        thresh = 400000;
end

t1_masked = t1;
t1_masked(t1 <= thresh) = 0; % im confused why you have to individually like threshold things?

figure;
imshow3Dfull(t1_masked);

%% seed growing on t1 
% sometimes you will have to play with the starting seed
% this see will be on the ICA
% [198 338 189];

if subject_code == "20191022_Reconstruction"
    seed = [189 318 196];
elseif subject_code == "20191112_Reconstruction"
    seed = [195 328 163
            234 324 163];
elseif subject_code == "20201008_Reconstruction"
    seed = [194 328 142
            231 331 142];
elseif subject_code == "20201016_Reconstruction"
    seed = [189 316 172
            234 317 172];
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
elseif subject_code == "20191029_Rec"
    seed = [ 
        191 338 193
        242 333 193 
        ];
elseif subject_code == "20201014_Reconstruction"
    seed = [ 
        196 326 93
        252 327 93 
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


