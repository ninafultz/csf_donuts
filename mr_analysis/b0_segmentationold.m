clear
close all
clc

GENERALDIR = '/exports/gorter-hpc/users/ninafultz/csf_donut/';
allSubjects = dir('/exports/gorter-hpc/users/ninafultz/csf_donut/csf*');
workingFolder = '/csf_donut/';
savingdir = '/reoriented/';
anatScanLoc = '/anat/';
anatScanLabel = '3dT1_0.9mm.nii';
templateLocation = '/exports/gorter-hpc/users/ninafultz/scripts/spm12/tpm/';
scansLoc = '/anat/';
b0Label = '*b0*';
addpath(templateLocation)

cd(GENERALDIR)
%% 

Subjects_to_Use = allSubjects;

c=1;

for s=1:numel(allSubjects)
    subject = allSubjects(s).name;
    if isfile(fullfile(subject, savingdir,"B0_properOrientation.nii"))
        Subjects_to_Use(c)=[];
    else
        c=c+1;
    end
end


segmentation = 1;
onlyfrangifilter = 1;



%% Anat segmentation
for s = 1:numel(Subjects_to_Use)

    subject = Subjects_to_Use(s).name;


    anatScanCurrent = dir([GENERALDIR subject anatScanLoc anatScanLabel]);

    anatscanname=anatScanCurrent.name;

    svdir = fullfile(GENERALDIR,subject,savingdir);

    fprintf('Subject: %s \n', subject)
    B0ScanLabel = 'B0_properOrientation';

    if segmentation

        disp('T1 segmentation')
        clear matlabbatch
        matlabbatch{1}.spm.spatial.preproc.channel.vols = {[fullfile(anatScanCurrent.folder ...
            , anatScanCurrent.name)]};
        matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[templateLocation 'TPM.nii,1']};
        matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[templateLocation 'TPM.nii,2']};
        matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[templateLocation 'TPM.nii,3']};
        matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[templateLocation 'TPM.nii,4']};
        matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[templateLocation 'TPM.nii,5']};
        matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[templateLocation 'TPM.nii,6']};
        matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1];
        spm_jobman('run', matlabbatch);
        clear matlabbatch


        %% Srt origin for B0 scan and masks equal

        B0scan = dir([GENERALDIR subject scansLoc b0Label]);


        img = flipud(niftiread(fullfile(B0scan.folder,B0scan.name)));
        voxelSize = [0.45 0.45 0.45];
        origin = [round(size(img,1)/2) round(size(img,2)/2) round(size(img,3)/2)];
        datatype = 16;
        newnii= make_nii(img, voxelSize, origin, datatype);

        save_nii(newnii,sprintf('%s\\B0_properOrientation.nii',svdir))

        clear B0scan img




        %% Coregistration between B0 and T1 masks

        disp('Performing coregistration between B0 and T1');

        x = spm_coreg([fullfile(svdir,'anat/','c3')  anatscanname], [fullfile(svdir,B0ScanLabel) '.nii']);
        M = spm_matrix(x);


        %CSF
        copyfile ([fullfile(svdir,'anat/','c3')  anatscanname], [fullfile(svdir,'anat/','c3_')  subject '.nii'])
        spm_get_space([fullfile(svdir,'anat/','c3_')  subject '.nii'], M * spm_get_space([fullfile(svdir,'anat/','c3_')  subject '.nii']));

        %WM
        copyfile ([fullfile(svdir,'anat/','c2')  anatscanname], [fullfile(svdir,'anat/','c2_')  subject '.nii'])
        spm_get_space([fullfile(svdir,'anat/','c2_')  subject '.nii'], M * spm_get_space([fullfile(svdir,'anat/','c2_')  subject '.nii']));

        %GM
        copyfile ([fullfile(svdir,'anat/','c1')  anatscanname], [fullfile(svdir,'anat/','c1_')  subject '.nii'])
        spm_get_space([fullfile(svdir,'anat/','c1_')  subject '.nii'], M * spm_get_space([fullfile(svdir,'anat/','c1_')  subject '.nii']));

         %Skull
        copyfile ([fullfile(svdir,'anat/','c5')  anatscanname], [fullfile(svdir,'anat/','c5_')  subject '.nii'])
        spm_get_space([fullfile(svdir,'anat/','c5_')  subject '.nii'], M * spm_get_space([fullfile(svdir,'anat/','c5_')  subject '.nii']));


        % %Label Scan
        % 
        % spm_get_space([svdir '\anatScan\clabels_Neuromorphometrics.nii'], M * spm_get_space([svdir '\anatScan\clabels_Neuromorphometrics.nii']));


        %% RESLICE GM/CSF/labels/T1 TO BOLD
        %CSF
        res_files = {[fullfile(svdir,B0ScanLabel) '.nii'];[fullfile(svdir,'anatScan/','c3_')  subject '.nii']};
        flags = struct('interp',4,'mask',1,'mean',0,'which',1,'wrap',[0 0 0]');
        spm_reslice(res_files,flags)

        %WM
        res_files = {[fullfile(svdir,B0ScanLabel) '.nii'];[fullfile(svdir,'anatScan/','c2_')  subject '.nii']};
        flags = struct('interp',4,'mask',1,'mean',0,'which',1,'wrap',[0 0 0]');
        spm_reslice(res_files,flags)

        %GM
        res_files = {[fullfile(svdir,B0ScanLabel) '.nii'];[fullfile(svdir,'anatScan/','c1_')  subject '.nii']};
        flags = struct('interp',4,'mask',1,'mean',0,'which',1,'wrap',[0 0 0]');
        spm_reslice(res_files,flags)

         %skull
        res_files = {[fullfile(svdir,B0ScanLabel) '.nii'];[fullfile(svdir,'anatScan/','c5_')  subject '.nii']};
        flags = struct('interp',4,'mask',1,'mean',0,'which',1,'wrap',[0 0 0]');
        spm_reslice(res_files,flags)


     

    end



end
