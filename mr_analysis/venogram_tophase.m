clear;

% goal: convert adc and fa maps to niftis, create frangi filter on inverted
% image
% register t2 maps to the b0 
%% Define project directory and subject code
project_directory = '/exports/gorter-hpc/users/ninafultz/';
project_name      = 'csf_donut';
subject_code      = 'csfdonut01';
plot_flag         = 1; % Set to 1 to enable plotting, 0 to disable

%% Paths
regDir         = fullfile(project_directory, project_name, subject_code, 'reg');
fa             = fullfile(project_directory, project_name, subject_code, 'fa');
adc            = fullfile(project_directory, project_name, subject_code, 'adc');
reoriented     = fullfile(project_directory, project_name, subject_code, 'reoriented');
biasfield      = fullfile(project_directory, project_name, subject_code, 'biasfield');
toolbox        = fullfile(project_directory, 'scripts', 'toolbox');
functions      = fullfile(project_directory, 'scripts', project_name, 'functions');

if strcmp(subject_code, 'csfdonut01')
    subject_par    = 'csfdonut01_angiogramvenogram';
    input_filename = 'Ppmr7t0849^X^^^_T2star_3D_0.6_lowPNS_6_1.PAR';
end

par_path       = fullfile(project_directory, project_name, subject_par, 'par');
reg_new        = fullfile(project_directory, project_name, subject_par, 'reg');

addpath(genpath(toolbox));
addpath(genpath(functions));

%% params

kernel  = 92;    % parameter for unwrapping
swi     = 4;    % swi weighting
masking = 0; % 0 means no mask (mask not tested)


%% 

cd(par_path)

[data_in, ~ ] = import_parrec_special_WT2_LH(1, '*'); % loads the raw data of all echoes (NOT YET MASKED!)

if plot_flag == 1
    figure;
    imshow3Dfull(squeeze(data_in(:, :, :, 6))); % Adjust the intensity range as needed
end
%% unwrapping venogram 

% So data_in(blablbal,1) is the magnitude of one slice one echo,...
% data_in(blabla,2) is the phase of that same slice
% data_up is the unwrapped phase

disp("Start unwrapping...")

data_size = size(data_in, 3);
echoes    = size(data_in, 4);

[data_up, data_swi] = my_unwrap2(...
data_in(:,:,1:data_size,1,1,1,1) .* exp(1i*data_in(:,:,1:data_size,1,1,1,2)),...
kernel, kernel, 1, 1, ...
1, swi );

data_up = zeros(size(data_in(:,:,1:data_size,1,1,1,1))); % Preallocate
data_swi = zeros(size(data_in(:,:,1:data_size,1,1,1,1))); % Preallocate

for echo = 1:echoes
    [data_up(:,:,:, echo), data_swi(:,:,:, echo)] = my_unwrap2(...
    data_in(:,:,1:data_size,echo,1,1,1) .* exp(1i*data_in(:,:,1:data_size,echo,1,1,2)),...
    kernel, kernel, 1, 1, ...
    1, swi );
end


if plot_flag == 1
    figure;
    imshow3Dfull(squeeze(data_up(:, :, :, 5))); % Adjust the intensity ...
    %range as needed
end

combinedVolume = cat(4, data_up(:,:,:, 1), data_up(:,:,:, 2), ...
data_up(:,:,:, 3), data_up(:,:,:, 4), data_up(:,:,:, 5), ...
data_up(:,:,:, 6));

% % Calculate the averaged volume
averagedVolume = mean(combinedVolume, 4);

if plot_flag == 1
    figure;
    imshow3Dfull(averagedVolume); % Adjust the intensity range as needed
end
% 
% % Load the NIfTI header information from one of the input files
% niftiInfo = niftiinfo(echo4File);

    cd(reg_new);
    newnii= make_nii(averagedVolume);
    svdir = fullfile(reoriented);
    save_nii(newnii,sprintf('venogram_unwrapped.nii'), reg_new);
    