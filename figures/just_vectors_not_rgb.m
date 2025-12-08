clear


GENERALDIR = 'R:\- Gorter\CSF_STREAM\Data\';
allSubjects = dir([GENERALDIR '*20201019_Reconstruction']);
subjectNb = 1;
subject = allSubjects(subjectNb); 
disp(subject.name)

physioFolder = '\Cardiac\T2prep';
physio = 'cardiac';
threshold = 150;

newFolder = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane'
physio = 'cardiac';

%% slices

load([newFolder,'\', subject.name, '\vectorsRGB\Vectors_RBGThresh150_WHOLEBRAIN.mat']);

%% Export vtk
x = 1:size(RGBmap_thresh_mean,1);
y = 1:size(RGBmap_thresh_mean,2);
z = 1:size(RGBmap_thresh_mean,3);

% % %figure 2A donut
% % x = 260:300; %1:size(RGBmap_thresh_mean,1);
% % y = 280:330; %260:300; %1:size(RGBmap_thresh_mean,2);
% % z = 90:140; %1:size(RGBmap_thresh_mean,3);

%figure 2B donut
x = 260:330; %1:size(RGBmap_thresh_mean,1);
y = 300:360; %260:300; %1:size(RGBmap_thresh_mean,2);
z = 250:320; %1:size(RGBmap_thresh_mean,3);

%acaexample 1
x = 200:350; %1:size(RGBmap_thresh_mean,1);
y = 250:480; %260:300; %1:size(RGBmap_thresh_mean,2);
z = 180:215; %1:size(RGBmap_thresh_mean,3);

%acaexample 2
x = 200:350; %1:size(RGBmap_thresh_mean,1);
y = 250:480; %260:300; %1:size(RGBmap_thresh_mean,2);
z = 195:205; %1:size(RGBmap_thresh_mean,3);
% 
% %acaexample 3 20191022_Reconstruction
x = 100:350; %1:size(RGBmap_thresh_mean,1);
y = 85:480; %260:300; %1:size(RGBmap_thresh_mean,2);
z = 200:240; %1:size(RGBmap_thresh_mean,3);
% 
% %figure 2B donut
% x = 270:330; %1:size(RGBmap_thresh_mean,1);
% y = 250:425; %260:300; %1:size(RGBmap_thresh_mean,2);
% z = 60:360; %1:size(RGBmap_thresh_mean,3);


x = 1:100; % 26
y = 120:200; % 36
z = 180:240; %50:450; % 250:449; % 21

x = 1:200; % 26
y = 150:500; % 36
z = 170:250; %50:450; % 250:449; % 21

x = 150:300; % 26
y = 250:555; % 36
z = 200:220; %50:450; % 250:449; % 21


%%
x = 240:280; % 26
y = 300:350; % 36
z = 200:300; %50:450; % 250:449; % 21


roi     = VectorF_thresh_mean(x, y, z, :);
rgbRoi  = RGBmap_thresh_mean(x, y, z, :);

[X Y Z] = meshgrid(y-1,x-1,z-1);

% roi = VectorF_thresh_mean;
% rgbRoi = RGBmap_thresh_mean;
roi(isnan(roi)) = 0;
rgbRoi(isnan(rgbRoi)) = 0;
roiName = ['HigherResThres150_dec4th_ICA_150_'];


for i = 1:3
    nameRGB = [newFolder '\' subject.name ...
        '\vectorsRGB\VectorF_' roiName sprintf('x%d-%d-y%d-%d-z%d-%d_RGB%d.vtk',x(1),x(end),y(1),y(end),z(1),z(end),i)];    
    vtkwrite(nameRGB, 'structured_grid', X,Y,Z, 'vectors', 'vector_field', squeeze(roi(:,:,:,2)),...
        squeeze(roi(:,:,:,1)),squeeze(roi(:,:,:,3)),'scalars', 'RGB', squeeze(rgbRoi(:,:,:,i)));
end


