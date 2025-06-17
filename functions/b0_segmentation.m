function b0_segmentation(project_directory, project_name, subject_code, scripts);

%edited by Nina Fultz, originally from Madda Debiasi
% 

GENERALDIR = fullfile(project_directory, project_name);
savingdir = fullfile(project_directory, project_name, subject_code, 'reg');

reoriented = fullfile(project_directory, project_name, subject_code, 'reoriented');
mkdir(reoriented);

% Dynamically list all subject directories matching the pattern
subjectPattern = fullfile(GENERALDIR, '*Reconstruction*');
allSubjects = dir(subjectPattern);

% Define relative paths for working directories and files
anatScanLoc = 'anat/'; % Anatomical scan location
anatScanLabel = '3dT1_0.9mm.nii'; % Anatomical scan label
scansLoc = 'anat/'; % Location for scans
b0Label = '*b0*'; % Pattern to identify b0 scans

% Define the template location for SPM12
templateLocation = fullfile(project_directory, 'scripts', 'spm12', 'tpm/');
addpath(templateLocation);

% Change directory to the project’s general directory
cd(GENERALDIR);

%% Filter subjects and process files

GENERALDIR = fullfile(project_directory, project_name);
savingdir = fullfile(project_directory, project_name, subject_code, 'reg');

reoriented = fullfile(project_directory, project_name, subject_code, 'reoriented');
mkdir(reoriented);

% Dynamically list all subject directories matching the pattern
subjectPattern = fullfile(GENERALDIR, '*');
allSubjects = dir(subjectPattern);

% Filter only directories
allSubjects = allSubjects([allSubjects.isdir] & ~startsWith({allSubjects.name}, '.'));

% Define file patterns
csfPattern = '*_CSF_properOrientation.nii'; % Pattern to find CSF file
b0Pattern = 'B0_properOrientation.nii';   % Pattern for the output B0 file

Subjects_to_Use = {};
c = 1;

for s = 1:numel(allSubjects)
    subjectDir = fullfile(GENERALDIR, allSubjects(s).name);
    csfFiles = dir(fullfile(subjectDir, scansLoc, csfPattern)); % Look for CSF files in the subject directory

    % Ensure only one CSF file matches
    if numel(csfFiles) > 1
        warning('Multiple CSF files found for subject: %s. Skipping.', allSubjects(s).name);
        continue;
    elseif isempty(csfFiles)
        fprintf('No CSF file found for subject: %s. Skipping.\n', allSubjects(s).name);
        continue;
    end

    csfFile = fullfile(csfFiles(1).folder, csfFiles(1).name); % Full path to the CSF file

    % Extract subject code from the CSF file name (e.g., 20191029_CSF_properOrientation.nii)
    subjectCodePrefix = extractBefore(csfFiles(1).name, '_');
    
    % Ensure subject code matches the directory name
    if ~contains(allSubjects(s).name, subjectCodePrefix)
        fprintf('Subject code mismatch for directory: %s. Skipping.\n', allSubjects(s).name);
        continue;
    end

    % Check if B0 file already exists
    b0File = fullfile(savingdir, replace(csfFiles(1).name, 'CSF', 'B0'));
    if isfile(b0File)
        fprintf('B0 file already exists for subject: %s. Skipping.\n', allSubjects(s).name);
        continue;
    end

    % Perform conversion (simulated here with copyfile)
    fprintf('Converting CSF file to B0 for subject: %s\n', allSubjects(s).name);
    b0FileFinal = fullfile(savingdir, 'B0_properOrientation.nii');
    copyfile(csfFile, b0File); % Replace with actual conversion logic if needed
    copyfile(b0File, b0FileFinal); % Replace with actual conversion logic if needed
    fprintf('File saved as: %s\n', b0File);

    % Keep track of processed subjects
    Subjects_to_Use{c} = allSubjects(s).name;
    c = c + 1;
end

fprintf('Processing completed. Subjects used: %d\n', numel(Subjects_to_Use));

segmentation = 1;
onlyfrangifilter = 1;

%% 

Subjects_to_Use = allSubjects;

c=1;

for s=1:numel(allSubjects)
    subject = allSubjects(s).name;
    if isfile(fullfile(savingdir,"B0_properOrientation.nii"))
        Subjects_to_Use(c)=[];
    else
        c=c+1;
    end
end

%% Anat segmentation
for s = 1:numel(Subjects_to_Use)

    subject = Subjects_to_Use(s).name;
    anatScanCurrent = dir([GENERALDIR '/' subject '/' anatScanLoc '/' anatScanLabel]);

    anatscanname=anatScanCurrent.name;

    svdir = savingdir;

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

        B0scan = dir([GENERALDIR '/' subject  '/' scansLoc '/' b0Label]);


        img = flipud(niftiread(fullfile(B0scan.folder,B0scan.name)));
        voxelSize = [0.45 0.45 0.45];
        origin = [round(size(img,1)/2) round(size(img,2)/2) round(size(img,3)/2)];
        datatype = 16;
        newnii= make_nii(img, voxelSize, origin, datatype);
        
        cd(svdir);
        save_nii(newnii,sprintf('B0_properOrientation.nii'))

        clear B0scan img




        %% Coregistration between B0 and T1 masks

        disp('Performing coregistration between B0 and T1');

        x = spm_coreg([fullfile(regDir,'c3')  anatscanname], [fullfile(svdir,B0ScanLabel) '.nii']);
        M = spm_matrix(x);


        %CSF
        copyfile ([fullfile(regDir,'c3')  anatscanname], [fullfile(regDir,'c3_')  subject '.nii'])
        spm_get_space([fullfile(regDir,'c3_')  subject '.nii'], M * spm_get_space([fullfile(regDir,'c3_')  subject '.nii']));

        %WM
        copyfile ([fullfile(regDir,'c2')  anatscanname], [fullfile(regDir,'c2_')  subject '.nii'])
        spm_get_space([fullfile(regDir,'c2_')  subject '.nii'], M * spm_get_space([fullfile(regDir,'c2_')  subject '.nii']));

        %GM
        copyfile ([fullfile(regDir,'c1')  anatscanname], [fullfile(regDir,'c1_')  subject '.nii'])
        spm_get_space([fullfile(regDir,'c1_')  subject '.nii'], M * spm_get_space([fullfile(regDir,'c1_')  subject '.nii']));

         %Skull
        copyfile ([fullfile(regDir,'c5')  anatscanname], [fullfile(regDir,'c5_')  subject '.nii'])
        spm_get_space([fullfile(regDir,'c5_')  subject '.nii'], M * spm_get_space([fullfile(regDir,'c5_')  subject '.nii']));

     

    end



end
