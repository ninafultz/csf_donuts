clear

GENERALDIR = 'R:\- Gorter\CSF_STREAM\Data\';
allSubjects = dir([GENERALDIR '*20201014_Reconstruction']);
subjectNb = 1;
subject = allSubjects(subjectNb); 
disp(subject.name)
refScanTemp = dir([subject.folder '\' subject.name '\ReferenceScan\Scan*.mhd']);
referenceScan = metaImageRead([refScanTemp.folder '\' refScanTemp.name]);
physioFolder = '\Cardiac\T2prep';
newFolder = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane'
physio = 'cardiac';
threshold = 150;
addpath('R:\- Gorter\- Personal folders\Fultz, N\scripts\csfdonuts_lydiane\toolbox\vtkwrite_toolbox');
% subject 11
%% WHOLE BRAIN
% slicesCor = 1:556;% larger slice
% slicesTra = 1:450; % larger slice %mca=244:246; mcaB=243:246
% slicesSag = 1:422;
suffixeTensor = '';
suffixeVector= '_WHOLEBRAIN';

%% MCA
slicesCor = 300:325;% larger slice
slicesTra = 290:325; % larger slice %mca=244:246; mcaB=243:246
slicesSag = 160:180;

slicesCor = 300:303;% larger slice
slicesTra = 310:313; % larger slice %mca=244:246; mcaB=243:246
slicesSag = 175:178;
% suffixeTensor = '_MCA';
suffixeVector= '_test';

%% 
referenceScan = imresize3(referenceScan(slicesTra,slicesCor, slicesSag),2);

%%
Mv=[1,0,0];
Pv=[0,1,0];
Sv=[0,0,1];
for p = 1:6
    disp(p)
    load([subject.folder '\' subject.name  physioFolder '\Results\' sprintf('DTIresult_phase%d%s.mat',p, suffixeTensor)])
%    VectorF_thresh = VectorF .* (referenceScan>threshold);

% Threshold VectorF
        mask = referenceScan > threshold;              % logical mask
        VectorF_thresh = VectorF;                      % keep original size
        for c = 1:size(VectorF,4)
            VectorF_thresh(:,:,:,c) = VectorF(:,:,:,c) .* mask;
        end
   
        VectorF_thresh(VectorF_thresh==0) = NaN;

    clear VectorF
    RGBmap_thresh = nan(size(VectorF_thresh,1),size(VectorF_thresh,2),3,size(VectorF_thresh,3));  
    for i = 1:size(FA,1)
        for j = 1:size(FA,2)
            for k = 1:size(FA,3)
                if sum(isnan(squeeze(VectorF_thresh(i,j,k,:)))) == 0 %if none of the components are nans
                    Ev= squeeze(VectorF_thresh(i,j,k,:));
                    RGBmap_thresh(i,j,1,k)=FA(i,j,k)*cos(atan2(norm(cross(Mv,Ev)),dot(Mv,Ev))); %red
                    RGBmap_thresh(i,j,2,k)=FA(i,j,k)*cos(atan2(norm(cross(Pv,Ev)),dot(Pv,Ev))); %green
                    RGBmap_thresh(i,j,3,k)=FA(i,j,k)*cos(atan2(norm(cross(Sv,Ev)),dot(Sv,Ev))); %blue
                end
            end
        end
    end
    RGBmap_thresh = permute(RGBmap_thresh,[1 2 4 3]);
%     rgbMapName = [subject.folder '\' subject.name  physioFolder '\Results\VectorsRGB\' sprintf('RGBphase%d%s.mat',p,suffixeVector)];
%     save(rgbMapName,'RGBmap_thresh','threshold','-v7.3');
    
    VectorF_thresh_allPh(:,:,:,:,p) = VectorF_thresh;
    RGBmap_thresh_allPh(:,:,:,:,p)= RGBmap_thresh;
end
% save('RGBmapThresh150.mat','RGBmap_thresh','-v7.3');
% figure,  imshow3Dfull(permute(RGBmap,[1 2 4 3]))
% figure,  imshow3Dfull(permute(fliplr(permute(RGBmap,[1 2 4 3])),[2 1 3 4]))

%% Average

RGBmap_thresh_mean = abs(mean(RGBmap_thresh_allPh,5));
VectorF_thresh_mean = abs(mean(VectorF_thresh_allPh,5));
save([subject.folder '\' subject.name  physioFolder '\Results\VectorsRGB\Vectors_RBGThresh150' suffixeVector '.mat'],'VectorF_thresh_mean','RGBmap_thresh_mean','-v7.3');

%% Export vtk
x = 1:size(RGBmap_thresh_mean,1);
y = 1:size(RGBmap_thresh_mean,2);
z = 1:size(RGBmap_thresh_mean,3);
[X Y Z] = meshgrid(y-1,x-1,z-1);

roi = VectorF_thresh_mean;
rgbRoi = RGBmap_thresh_mean;
roi(isnan(roi)) = 0;
rgbRoi(isnan(rgbRoi)) = 0;
roiName = ['HigherResThres150' suffixeVector];
for i = 1:3
    nameRGB = [subject.folder '\' subject.name  physioFolder '\Results\VectorsRGB\VectorF_' roiName sprintf('x%d-%d-y%d-%d-z%d-%d_RGB%d.vtk',x(1),x(end),y(1),y(end),z(1),z(end),i)];    
    vtkwrite(nameRGB, 'structured_grid', X,Y,Z, 'vectors', 'vector_field', squeeze(roi(:,:,:,2)),...
        squeeze(roi(:,:,:,1)),squeeze(roi(:,:,:,3)),'scalars', 'RGB', squeeze(rgbRoi(:,:,:,i)));
end

%%
metaImageWrite(referenceScan,[subject.folder '\' subject.name  physioFolder '\Results\VectorsRGB\referenceScanHigherRes' suffixeVector '.mhd']);

