dataSetDir = 'D:\BRC\CometAnalyser\SampleImages\Fluorescence_dati01';
imgDir = fullfile(dataSetDir,'trainingImages');
labelDir = fullfile(dataSetDir,'trainingMasks');
VALimgDir = fullfile(dataSetDir,'valImages');
VALlabelDir = fullfile(dataSetDir,'valMasks');

Vimds = imageDatastore(VALimgDir);
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
Vpxds = pixelLabelDatastore(VALlabelDir, classes, labelIDs);

C = readimage(pxds,1);

cmap = [
    1 0 0   % head
    0 0 1   % tail
    0 0 0   % background
    ];


B = labeloverlay(I,C,'ColorMap',cmap);
figure, imshow(B)
pixelLabelColorbar(cmap,classes);

tbl = countEachLabel(pxds)

frequency = tbl.PixelCount/sum(tbl.PixelCount);

bar(1:numel(classes),frequency)
xticks(1:numel(classes)) 
xticklabels(tbl.Name)
xtickangle(45)
ylabel('Frequency')

% [imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = partitionCamVidData(imds,pxds);

% numTrainingImages = numel(imdsTrain.Files)
numTrainingImages = numel(imds.Files)

% numValImages = numel(imdsVal.Files)
numValImages = numel(Vimds.Files)

% numTestingImages = numel(imdsTest.Files)

% Specify the network image size. This is typically the same as the traing image sizes.
imageSize = [1024 1360 3];

% Specify the number of classes.
numClasses = numel(classes);

% Create DeepLab v3+.
lgraph = deeplabv3plusLayers(imageSize, numClasses, "resnet18");

imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq

pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = replaceLayer(lgraph,"classification",pxLayer);

% Define validation data.
dsVal = combine(Vimds,Vpxds);

% Define training options. 
options = trainingOptions('sgdm', ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',8,...
    'LearnRateDropFactor',0.3,...
    'Momentum',0.9, ...
    'InitialLearnRate',1e-3, ...
    'L2Regularization',0.005, ...
    'ValidationData',dsVal,...
    'MaxEpochs',10, ...  
    'MiniBatchSize',1, ...
    'Shuffle','every-epoch', ...
    'CheckpointPath', tempdir, ...
    'VerboseFrequency',2,...
    'ExecutionEnvironment','cpu',...
    'Plots','training-progress',...
    'ValidationFrequency', 5,...
    'ValidationPatience', 4);

dsTrain = combine(imds, pxds);


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

% I = readimage(imdsTest,35);
I = imread('D:\BRC\CometAnalyser\SampleImages\Fluorescence_dati01\sf.A549 sip53 8.tif');
C = semanticseg(I, net);

B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
figure, imshow(B)
pixelLabelColorbar(cmap, classes);

expectedResult = readimage(pxdsTest,35);
actual = uint8(C);
expected = uint8(expectedResult);
imshowpair(actual, expected)

iou = jaccard(C,expectedResult);
table(classes,iou)

pxdsResults = semanticseg(imdsTest,net, ...
    'MiniBatchSize',4, ...
    'WriteLocation',tempdir, ...
    'Verbose',false);

metrics = evaluateSemanticSegmentation(pxdsResults,pxdsTest,'Verbose',false);

metrics.DataSetMetrics
metrics.ClassMetrics
