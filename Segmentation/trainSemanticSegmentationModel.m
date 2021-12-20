function [bool, message] = trainSemanticSegmentationModel(path,options)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 14, 2021
% NAME: trainSemanticSegmentationModel (version 1.0)
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
% REFERENCE: [1] Chen, L., Y. Zhu, G. Papandreou, F. Schroff, and H. Adam.
% "Encoder-Decoder with Atrous Separable Convolution for Semantic Image
% Segmentation." Computer Vision — ECCV 2018, 833-851. Munic, Germany:
% ECCV, 2018.
%
% ### deeplabv3plusLayers ###
%
% https://www.mathworks.com/help/vision/ref/deeplabv3pluslayers.html
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

bool = 0;
message = [];
baseFolder = path;

if ~exist(fullfile(baseFolder,'Images'),'dir') || ~exist(fullfile(baseFolder,'Masks'),'dir')
    message = {'The selected folder does not contain annotated data.';...
                'It does not contain the two required subfolders named ''Images'' and ''Masks''.'};
    return
end

imgDir = fullfile(baseFolder,'Images');
labelDir = fullfile(baseFolder,'Masks');

if isempty(dir(fullfile(imgDir,'*.png'))) || isempty(dir(fullfile(labelDir,'*.png')))
    message = {'The selected folder does not contain annotated data.';...
                'Image files are missing from subfolder';...
                '(regquired extension is PNG)'};
    return
end

imds = imageDatastore(imgDir);
if numel(imds.Files)<6
    message = {'Not enough training sample.';...
                'Please annotate more images for the sake of reliable result';...
                '(minimum requirement is 6 images with labels)'};
    return
end

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
imageFreq(isnan(imageFreq)) = min(imageFreq) * 0.00001;
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
    'LearnRateDropFactor',0.5,...
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
modelName = fullfile(baseFolder,[datestr(now,30),'_preTrainedNetwork_',num2str(metrics.DataSetMetrics.GlobalAccuracy),'.mat']);
helpdlg(['Saving trained model at path: ', modelName], 'Save model')
save(modelName,'net')
helpdlg('Trained model is saved.', 'Train complete')
bool = 1;