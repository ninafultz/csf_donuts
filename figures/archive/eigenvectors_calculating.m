%% calculating eigenpairs (λ1e1, λ2e2, λ2e2) (will give all principal diffusivity and orientation)
%  nina fultz nov 27th, 2025
clear
close all

clear;

GENERALDIR = 'R:\- Gorter\CSF_STREAM\Data\';
newFolder  = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\';
physioFolder = '\Cardiac\T2prep';

cd(GENERALPATH)

allsubjects = dir([GENERALPATH '*_Reconstruction*']);

Subjects_to_Use = allsubjects;



%% load all tensors 


load(fullfile(subject.folder, subject.name, physioFolder, 'Results', ...
            sprintf('TensorPhase%dNoNeg.mat'));

tensor_registered = mean(tensor_registered_T2prep, 4); % Compute the mean along the 4th dimension

    %% GenerateDiffusionImagesFullBrain


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
            DTIdata(i).VoxelData =single(tensor_registered(:,:,:,i));
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
            [VectorF1,VectorF2,VectorF3]=DTI_eigenpairs(DTIdata,parameters)


            %flipping vectors CHECK ORIENTATION 
            vector_f1 = fliplr(permute (flipud(VectorF1), [3 2 1]));
            vector_f2 = fliplr(permute (flipud(VectorF2), [3 2 1]));
            vector_f3 = fliplr(permute (flipud(VectorF3), [3 2 1]));

                % saving
            outDir = fullfile(newFolder, subject.name, 'eigenpairs');
            mkdir(outDir);
        
            save(fullfile(outDir, 'eigenpairs.mat'),'vector_f1', ...
                'vector_f2','vector_f3','-v7.3');

        end
    end


