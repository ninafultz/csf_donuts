%% FA calculation but now only with two components - radial diffusivity 
clear
close all

addpath('U:\Matlab')
addpath('U:\Projects\CLEARBRAIN\MATLABSCRIPTS')
GENERALPATH = 'U:\Projects\CLEARBRAIN\';

cd(GENERALPATH)

allsubjects = dir([GENERALPATH 'CLEAR*']);

Subjects_to_Use = allsubjects;

c=1;

for s=1:numel(allsubjects)

    subject = allsubjects(s).name;

    if isfolder([subject '\Results'])
        Subjects_to_Use(c)=[];
    else
        if isfolder([subject '\ReconstructedData'])
            c=c+1;
        else
            Subjects_to_Use(c)=[];
        end

    end


end





for i = 1:numel(Subjects_to_Use)


    PATHSUBJECT = [Subjects_to_Use(i).folder '\' Subjects_to_Use(i).name '\'];

    fprintf('Subject: %s \n', Subjects_to_Use(i).name)

    cd(PATHSUBJECT)
    Bdir = 0:6;
    nameTag = '';

    runRegistration = 1;
    runFullBrainGeneration = 1;
    runADC = 1;

    plotImages = 0;

    mkdir('Registration/')
    mkdir('Results/')
    savePathResults = [PATHSUBJECT 'Results\'];

    %% Registration
    if runRegistration == 1
        disp('Registration')
        cd('Registration\')
        elastixPath = 'U:\Matlab\elastix\elastix.exe ';
        registrationFile = 'U:\Matlab\par.glymphBONN.txt ';
        tmp = dir(sprintf('%sReconstructedData\\*_b0*.nii',PATHSUBJECT));
        referenceScan = [tmp.folder '\' tmp.name];

        % elastix for all mean images
        for s = Bdir
            fprintf('Registration elastix scan %d\n',s)
            if s==0
                tmp = dir(sprintf('%sReconstructedData\\*b%d*.nii ',PATHSUBJECT,s));
            else
                tmp = dir(sprintf('%sReconstructedData\\*dir%d*.nii ',PATHSUBJECT,s));
            end
            currentScan = [tmp.folder '\' tmp.name];
            outputdir = sprintf('scanB%d',s);
            mkdir(outputdir)
            commandElastix = [elastixPath ' -f ' referenceScan ' -m ' currentScan ' -p ' registrationFile ' -out ' outputdir '\'];
            [temp1,temp2] = system(['powershell ' commandElastix]);
        end
        cd('..')
    end


    %% Full Brain Data Generation
    if runFullBrainGeneration ==1
        disp('runFullBrainGeneration')
        tensor_registered=[];
        scanIndex=1;
        cd([PATHSUBJECT '\Registration'])
        for scan= Bdir
            disp(scan);
            pathRegisteredData = dir(sprintf('scan*B%d',scan));
            cd(pathRegisteredData.name)
            temp = niftiread('result.0.nii');

            %modify header in B0 scan

            voxelSize = [0.45 0.45 0.45];
            origin = [round(size(temp,1)/2) round(size(temp,2)/2) round(size(temp,3)/2)];
            datatype = 16;

            %to match the right orientation with the gradient H (added by MD)

            temp=rot90(permute(temp,[3 2 1]),2);

            tensor_registered(:,:,:,scanIndex) = temp;
            cd('..')
            scanIndex=scanIndex+1;
        end
        indices = tensor_registered<0; % Set negative voxels due to registration to 0
        for i=1:size(indices,1)
            for j=1:size(indices,2)
                for k=1:size(indices,3)
                    if sum(indices(i,j,k,:))~=0
                        tensor_registered(i,j,k,:) = 0;
                    end
                end
            end
        end
        save(sprintf('%sTensorNoNeg.mat',savePathResults), 'tensor_registered', '-v7.3')
        cd('..')
    end

    if plotImages == 1
        %   figure, imshow3Dfull(tensor_registered(:,:,:,1),[0 5000]) % show nn crushed scan
        figure, imshow3Dfull(squeeze(tensor_registered(20,:,:,:)),[0 1e-5])
    end
    clear temp indices Data_csstack

    %% GenerateDiffusionImagesFullBrain
    if runADC == 1
        disp('runADC')
        cd(savePathResults)
        if exist('tensor_registered', 'var') == 0
            load('Results/TensorNoNeg.mat')
        end

        DTIdata=struct();
        % The test data used is from the opensource QT Fiber-Tracking, NLM insight registration & Segmentation Toolkit)
        % Magnetic Gradients of data volumes
        % %my directions are:
        H=[0 0 0;...
            1 1 0;...
            1 0 1; ...
            0 1 1 ; ...
            1 -1 0; ...
            1 0 -1; ...
            0 1 -1];
        
        %  Read the MRI (DTI) voxeldata volumes
        for i=1:7
            DTIdata(i).VoxelData =single(tensor_registered(:,:,:,i)); %for dataset acquired after circa 4thJuly2024
            DTIdata(i).Gradient = H(i,:);
            DTIdata(i).Bvalue=13; % depends on VENC (here for 0.5mm/s in 2 directions)
        end

        % added to aviod problems in for loop with different subjects (MD)
        clear tensor_registered

        % Constants DTI
        parametersDTI=[];

        tresholdvalue = [0 ; 0.2];

        for i=1:numel(tresholdvalue)
            parametersDTI.BackgroundTreshold=tresholdvalue(i);

            parametersDTI.WhiteMatterExtractionThreshold=0; % was 0.1
            parametersDTI.textdisplay=true;

            % Perform DTI calculation
            [ADC,FA,VectorF,DifT]=DTI(DTIdata,parametersDTI);

            adc = fliplr(permute (flipud(ADC), [3 2 1]));
            fa = fliplr(permute (flipud(FA), [3 2 1]));


            %save results
            save(['RD_' sprintf('Thres%d_b0orientation.mat',parametersDTI.BackgroundTreshold)],'fa','-v7.3');
            newnii= make_nii(adc, voxelSize, origin, datatype);
            save_nii(newnii,sprintf('RDThres%d.nii',parametersDTI.BackgroundTreshold))
        end

    end

    cd('..')

end

