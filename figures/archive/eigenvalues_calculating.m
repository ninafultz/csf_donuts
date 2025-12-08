%% Main registration and ADC calculation
clear
close all

addpath('U:\Matlab')
addpath('U:\Projects\CLEARBRAIN\MATLABSCRIPTS')
GENERALPATH = 'U:\Projects\CLEARBRAIN\';

cd(GENERALPATH)

allsubjects = dir([GENERALPATH 'CLEAR*']);

Subjects_to_Use = allsubjects;



%% load all tensors 


tensor_registered(i,j,k,:) = 0;





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
            save(sprintf('DTIresultsThres%d_sagittal.mat',parametersDTI.BackgroundTreshold),'FA','VectorF','ADC','DifT','-v7.3');
            save(['ADC_' sprintf('Thres%d_b0orientation.mat',parametersDTI.BackgroundTreshold)], 'adc','-v7.3');
            save(['FA_' sprintf('Thres%d_b0orientation.mat',parametersDTI.BackgroundTreshold)],'fa','-v7.3');
            newnii= make_nii(adc, voxelSize, origin, datatype);
            save_nii(newnii,sprintf('ADCThres%d.nii',parametersDTI.BackgroundTreshold))
            newnii= make_nii(fa, voxelSize, origin, datatype);
            save_nii(newnii,sprintf('FAThres%d.nii',parametersDTI.BackgroundTreshold))
        end
    end


