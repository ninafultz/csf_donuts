clear
close all
clc

GENERALDIR = 'U:\Projects\7FTLD\';
allSubjects = dir('U:\Projects\7FTLD\7*');

pvs_folder = 'PVS_Segmentation';
dti_folder = 'Results';

svdir = 'pvs_mob_fa_mask_before_nan';


addpath('U:\Matlab\')

cd(GENERALDIR)

subject_info = readtable('U:\Projects\7FTLD_notes_results\7FTLD_subjectinfo.csv');
Subjects_to_Use=subject_info.subject;
cso_all_i = subject_info.cso_i;
cso_all_f = subject_info.cso_f;


for s= 34%:numel(Subjects_to_Use)

    subject = char(Subjects_to_Use(s));

    disp(subject)

    pvs_results(s).subject = subject;
    mkdir(subject,svdir)

    cso = (cso_all_i(s):cso_all_f(s))';

    pvs_seg = niftiread([fullfile(GENERALDIR,subject,pvs_folder ,'PVSsegm_'), subject,'.nii']);
    b0 = niftiread([fullfile(GENERALDIR,subject,pvs_folder ,'B0_properOrientation.nii')]);

    if isfile([fullfile(GENERALDIR,subject,dti_folder ,'ADC_Thres1.000000e-05_sagittal.mat')])

        ADC = load([fullfile(GENERALDIR,subject,dti_folder ,'ADC_Thres1.000000e-05_sagittal.mat')]).ADC;
        FA = load([fullfile(GENERALDIR,subject,dti_folder ,'FA_Thres1.000000e-05_sagittal')]).FA;
    else
        ADC = load([fullfile(GENERALDIR,subject,dti_folder ,'ADC_Thres1.000000e-08_sagittal.mat')]).ADC;
        FA = load([fullfile(GENERALDIR,subject,dti_folder ,'FA_Thres1.000000e-08_sagittal')]).FA;
    end

    adc = fliplr(flip(flip (permute (ADC, [3 2 1]),1),3));
    fa = fliplr(flip(flip (permute (FA, [3 2 1]),1),3));

    clear ADC FA

    %remove outside of brain / generate brain mask
    loc= 'anat';
    gm_mask= niftiread([fullfile(GENERALDIR,subject,pvs_folder,loc ,'rc1_'), subject,'.nii']);
    wm_mask= niftiread([fullfile(GENERALDIR,subject,pvs_folder,loc ,'rc2_'), subject,'.nii']);
    csf_mask= niftiread([fullfile(GENERALDIR,subject,pvs_folder,loc ,'rc3_'), subject,'.nii']);

    brain_mask =imbinarize((csf_mask>10) + (wm_mask>10) + (gm_mask >10));

    clear gm_mask wm_mask csf_mask

    brain_mask = imclose(brain_mask,strel('sphere',3));




end

% writetable(struct2table(pvs_results),[fullfile(GENERALDIR ,'pvs_result_v2.csv')])