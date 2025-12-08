%% segmenting t1s


clear;
%% 

GENERALDIR = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\'
addpath(genpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\csfdonuts_lydiane\functions'));

allSubjects = dir([GENERALDIR '*20201014_Reconstruction']);
subjectNb = 1;
subject = allSubjects(subjectNb); 
disp(subject.name)

par_path = dir([subject.folder '\' subject.name '\par\*3d*PAR']);
folder = par_path.folder;

% load par files
cd(folder);
[img_data, ~ ] = import_parrec_special_WT2_LH(1, '*');


metaImageWrite(img_data,[subject.folder '\' subject.name '\mhd\' '3dT1.mhd']);
