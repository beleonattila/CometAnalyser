function trainSemanticSegmentationModel(path,options)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 14, 2017
% NAME: ComputeFeatures (version 1.0)
%
% INPUT:
% 	path                Path of annotadet dataset folder
%   options             Training options parameter
%                       (MaxEpoch, LearnRater, etc...)
%
%
% OUTPUT:
%   Pre-trained model saved to the input path folder.
%
% The function builds a 'Resnet18' model, then train it with presegmented
% images from input 'path' folder.
%
% Copyright © 2021 Filippo Piccinini
% Istituto Scientifico Romagnolo per lo Studio e la Cura dei Tumori (IRST) 
% IRCCS, Meldola (FC), Italy. All rights reserved.
%
% This program is free software; you can redistribute it and/or modify it 
% under the terms of the GNU General Public License version 2 (or higher) 
% as published by the Free Software Foundation. This program is 
% distributed WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
% General Public License for more details.

baseFolder = path;

imgDir = fullfile(baseFolder,'Images');
labelDir = fullfile(baseFolder,'Masks');

imds = imageDatastore(imgDir);

I = readimage(imds,1);
figure, imshow(I)

classes = [
    "Head"
    "Tail"
    "Backgroung"
    ];

labelIDs = {255; 127; 0};

pxds = pixelLabelDatastore(labelDir,classes,labelIDs);

C = readimage(pxds,1);

cmap = [
    1 0 0   % head
    0 0 1   % tail
    0 0 0   % background
    ];


B = labeloverlay(I,C,'ColorMap',cmap);
figure, imshow(B)
pixelLabelColorbar(cmap,classes);

tbl = countEachLabel(pxds);

frequency = tbl.PixelCount/sum(tbl.PixelCount);

bar(1:numel(classes),frequency)
xticks(1:numel(classes)) 
xticklabels(tbl.Name)
xtickangle(45)
ylabel('Frequency')

[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = partitionCometData(imds,pxds);

numTrainingImages = numel(imdsTrain.Files)
% numTrainingImages = numel(imds.Files)

numValImages = numel(imdsVal.Files)
% numValImages = numel(Vimds.Files)

numTestingImages = numel(imdsTest.Files)

% Specify the network image size. This is typically the same as the traing image sizes.
[w, h, c] = size(I);
imageSize = [w, h, c];

% Specify the number of classes.
numClasses = numel(classes);

% Create DeepLab v3+.
lgraph = deeplabv3plusLayers(imageSize, numClasses, "resnet18");

imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;

pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = replaceLayer(lgraph,"classification",pxLayer);

% Define validation data.
dsVal = combine(imdsVal,pxdsVal);

% Define training options. 
if isempty(options)
    options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',8,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.9, ...
    'InitialLearnRate',1e-3, ...
    'L2Regularization',0.005, ...
    'ValidationData',dsVal,...
    'MaxEpochs',5, ...  
    'MiniBatchSize',1, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',2,...
    'ExecutionEnvironment','cpu',...
    'Plots','training-progress',...
    'ValidationFrequency', numTrainingImages,...
    'ValidationPatience', 4);
else
    options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',str2double(options.LearnRateDropPeriod),...
    'LearnRateDropFactor',str2double(options.LearnRateDropFactor),...
    'Momentum',str2double(options.Momentum), ...
    'InitialLearnRate',str2double(options.InitialLearnRate), ...
    'L2Regularization',str2double(options.L2Regularization), ...
    'ValidationData',dsVal,...
    'MaxEpochs',str2double(options.MaxEpoch), ...  
    'MiniBatchSize',str2double(options.MiniBatchSize), ...
    'Shuffle',options.ShuffleData, ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',2,...
    'ExecutionEnvironment',options.ExecutionEnvironment,...
    'Plots','training-progress',...
    'ValidationFrequency', numTrainingImages,...
    'ValidationPatience', str2double(options.ValidationPatience));
end
dsTrain = combine(imdsTrain, pxdsTrain);

xTrans = [-10 10];
yTrans = [-10 10];
dsTrain = transform(dsTrain, @(data)augmentImageAndLabel(data,xTrans,yTrans));

doTraining = true;
if doTraining
    [net, info] = trainNetwork(dsTrain,lgraph,options);
else
    data = load(pretrainedNetwork); 
    net = data.net;
end

idx = randi(numTestingImages);
I = readimage(imdsTest,idx);
C = semanticseg(I, net);

B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
figure, imshow(B)
pixelLabelColorbar(cmap, classes);

expectedResult = readimage(pxdsTest,idx);
actual = uint8(C);
expected = uint8(expectedResult);
imshowpair(actual, expected)

iou = jaccard(C,expectedResult);
table(classes,iou)

pxdsResults = semanticseg(imdsTest,net, ...
    'MiniBatchSize',1, ...
    'WriteLocation',tempdir, ...
    'Verbose',false);

metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTest,'Verbose',false);

metrics.DataSetMetrics
metrics.ClassMetrics

% Check the writting permission in standAlone version!
save(fullfile(baseFolder,[datestr(now,30),'_preTrainedNetwork_',num2str(metrics.DataSetMetrics.GlobalAccuracy),'.mat']),'net')