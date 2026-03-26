%% UNet to define vessel vs. background 
% two stages: 1) defining vessel mask on adc 
%             2) defining if it is M1 or M2

% Stage 1 - Binary segmentation (vessel vs. background)
imageSize = size(adc);   % height, width, channels (1 = grayscale)
numClasses = 2;            % background, vessel

lgraph1 = unetLayers(imageSize, numClasses, ...
    'EncoderDepth', 4, ...          % 4 encoder/decoder stages
    'NumFirstEncoderFilters', 64);  % 64 filters in first layer

% Inspect the network
analyzeNetwork(lgraph1);

% Assumes you have:
%   images/ folder with niftis 
%   masks_stage1/ folder with corresponding binary masks
%              pixel value 0 = background, 1 = vessel

imds1 = imageDatastore('images/', ...
    'FileExtensions', {'.png', '.tif'});

% Masks must be categorical pixel label datastores
classNames1 = {'background', 'vessel'};
labelIDs1   = {0, 1};

pxds1 = pixelLabelDatastore('masks_stage1/', classNames1, labelIDs1);

% Combine into a pixelLabelImageDatastore
ds1 = pixelLabelImageDatastore(imds1, pxds1);

% Train/validation split
numFiles = numel(imds1.Files);
splitIdx = floor(0.8 * numFiles);

trainDS1 = subset(ds1, 1:splitIdx);
valDS1   = subset(ds1, splitIdx+1:numFiles);

%%
% Count pixel label frequencies to compute class weights
tbl = countEachLabel(pxds1);
totalPixels = sum(tbl.PixelCount);
frequency   = tbl.PixelCount / totalPixels;
classWeights1 = 1 ./ frequency;  % inverse frequency weighting

% Apply weights to the pixel classification layer
% Find and replace the final classification layer
lgraph1 = replaceLayer(lgraph1, 'Softmax-Layer', ...
    pixelClassificationLayer('Name', 'output', ...
                             'Classes', classNames1, ...
                             'ClassWeights', classWeights1));

%%
options1 = trainingOptions('adam', ...
    'InitialLearnRate',     1e-4, ...
    'MaxEpochs',            50, ...
    'MiniBatchSize',        4, ...
    'Shuffle',              'every-epoch', ...
    'ValidationData',       valDS1, ...
    'ValidationFrequency',  10, ...
    'Plots',                'training-progress', ...
    'Verbose',              true);

[net1, info1] = trainNetwork(trainDS1, lgraph1, options1);

% Save trained model
save('unet_stage1.mat', 'net1');