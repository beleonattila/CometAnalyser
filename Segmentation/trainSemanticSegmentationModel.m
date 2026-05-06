function [bool, message, savedModelPath] = trainSemanticSegmentationModel(patchPath, preTrainedModelPath, outputPath, userOptions)

% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: May 01, 2026
% NAME: trainSemanticSegmentationModel (version 2.0)
%
% User-facing fine-tuning pipeline for CometAnalyser U-Net segmentation.
% Fine-tunes a pre-trained model on user-provided data.
%
% Expects pre-processed patch dataset (run preprocessPatchDataset first).
% Uses existing partitionCometData for train/val/test split.
% All hyperparameters passed via userOptions struct from the app UI.
%
% INPUT:
%   patchPath           Path to patch dataset folder (Images/ + Masks/)
%   preTrainedModelPath Path to pre-trained .mat model file
%   outputPath          Path where fine-tuned model will be saved
%   userOptions         Struct with fields:
%                           .MaxEpoch               number of epochs
%                           .MiniBatchSize          e.g. '4'
%                           .ValidationPatience     e.g. '6'
%                           .ExecutionEnvironment   'auto','cpu','gpu'
%                           .InitialLearnRate       e.g. '1e-5'
%                       (L2Regularization and ShuffleData are fixed
%                        internally to match the pre-trained model)
%
% OUTPUT:
%   bool                1 on success, 0 on failure
%   message             Error message cell array if failed, empty otherwise
%
% USAGE:
%   opts.MaxEpoch            = '20';
%   opts.MiniBatchSize       = '4';
%   opts.ValidationPatience  = '6';
%   opts.ExecutionEnvironment = 'auto';
%   [bool, msg] = trainSemanticSegmentationModel(
%       'data/patches', 'models/pretrained.mat', 'models/', opts);

global progressDLG

bool    = 0;
message = [];

classNames = ["Head", "Tail", "Background"];
labelIDs   = [255 127 0];
numClasses = numel(classNames);
% Fixed: must match the pre-trained model's architecture and patch pipeline.
patchSize  = [512 512];
cmap       = [1 0 0; 0 0 1; 0 0 0];

% -------------------------------------------------------------------------
% Validate patch folder
% -------------------------------------------------------------------------
imgDir = fullfile(patchPath, 'Images');
mskDir = fullfile(patchPath, 'Masks');

if ~exist(imgDir, 'dir') || ~exist(mskDir, 'dir')
    message = {'Patch folder structure invalid.'; ...
               'Expected Images/ and Masks/ subfolders.'; ...
               'Please run preprocessPatchDataset first.'};
    return
end

imgFiles = dir(fullfile(imgDir, '*.tif'));
mskFiles = dir(fullfile(mskDir, '*.png'));

if isempty(imgFiles)
    message = {'No .tif patch files found in Images/.'; ...
               'Please run preprocessPatchDataset first.'};
    return
end

if numel(imgFiles) < 6
    message = {'Not enough patches for training (minimum 6).'; ...
               'Please annotate more images and re-run preprocessPatchDataset.'};
    return
end

if numel(imgFiles) ~= numel(mskFiles)
    message = {sprintf('Image/mask count mismatch: %d images, %d masks.', ...
                numel(imgFiles), numel(mskFiles))};
    return
end

% -------------------------------------------------------------------------
% Validate pre-trained model
% -------------------------------------------------------------------------
if ~exist(preTrainedModelPath, 'file')
    message = {'Pre-trained model file not found.'; ...
               ['Path: ', preTrainedModelPath]};
    return
end

[~, ~, ext] = fileparts(preTrainedModelPath);
if ~strcmp(ext, '.mat')
    message = {'Invalid model file. Expected a .mat file.'};
    return
end

% -------------------------------------------------------------------------
% Load pre-trained model
% -------------------------------------------------------------------------
try
    data = load(preTrainedModelPath);
    if isfield(data, 'net')
        net = data.net;
    elseif isfield(data, 'netFinal')
        net = data.netFinal;
    elseif isfield(data, 'netAvg')
        net = data.netAvg;
    else
        message = {'No valid network found in model file.'; ...
                   'Expected field: net, netFinal, or netAvg.'};
        return
    end
    fprintf('Pre-trained model loaded: %s\n', preTrainedModelPath);
catch me
    message = {'Failed to load pre-trained model.'; me.message};
    return
end

% -------------------------------------------------------------------------
% Build datastores
% -------------------------------------------------------------------------
imds = imageDatastore(imgDir, ...
    'FileExtensions', '.tif', ...
    'ReadFcn',        @readPatchImage);

pxds = pixelLabelDatastore(mskDir, classNames, labelIDs);

% -------------------------------------------------------------------------
% Visualize class distribution
% -------------------------------------------------------------------------
tbl       = countEachLabel(pxds);
frequency = tbl.PixelCount / sum(tbl.PixelCount);

figure('Name', 'Class Distribution')
bar(1:numClasses, frequency)
xticks(1:numClasses)
xticklabels(tbl.Name)
xtickangle(45)
ylabel('Pixel Frequency')
title('Class distribution in patch dataset')

fprintf('Class frequencies:\n')
for i = 1:numClasses
    fprintf('  %-12s %.4f\n', classNames(i), frequency(i));
end

% -------------------------------------------------------------------------
% Verify patch dimensions
% -------------------------------------------------------------------------
I = readimage(imds, 1);
[h, w, ~] = size(I);
% Fixed: must match the pre-trained model architecture.
encoderDepth = 4;
reqDiv = 2^encoderDepth;

if mod(h, reqDiv) ~= 0 || mod(w, reqDiv) ~= 0
    message = {sprintf('Patch dimensions %dx%d not divisible by %d.', h, w, reqDiv); ...
               'Please re-run preprocessPatchDataset with compatible patch size.'};
    return
end

imageSize = [h w];
fprintf('Patch size confirmed: %dx%d\n', h, w);

% -------------------------------------------------------------------------
% Train/val/test split using existing partitionCometData
% -------------------------------------------------------------------------
[imdsTrain, imdsVal, imdsTest, pxdsTrain, pxdsVal, pxdsTest] = ...
    partitionCometData(imds, pxds);

numTrainingImages = numel(imdsTrain.Files);
numTestingImages  = numel(imdsTest.Files);

fprintf('Split — Train: %d  Val: %d  Test: %d\n', ...
    numTrainingImages, numel(imdsVal.Files), numTestingImages);

% -------------------------------------------------------------------------
% Loss function
% -------------------------------------------------------------------------
% Fixed: matches expert training loss balance; changing risks destabilizing fine-tuning.
lossFunc = @(Y, T) combinedLoss(Y, T, 0.7, 0.3);

% -------------------------------------------------------------------------
% Augmentation parameters — fixed to match pre-trained model training conditions.
% Changing these shifts the augmentation distribution from what the backbone
% features were learned on, risking instability or undoing learned invariances.
% -------------------------------------------------------------------------
augParams.xTrans           = [-30 30];
augParams.yTrans           = [-30 30];
augParams.rotVector        = [-90 90];
augParams.scaleVector      = [0.8 1.2];
augParams.intensityRange   = [0.7 1.5];
augParams.gammaRange       = [0.7 1.3];
augParams.maxNoiseStd      = 0.02;
augParams.maxBlurSigma     = 1.5;
augParams.vignetteStrength = 0.3;
augParams.doFlip           = true;

% -------------------------------------------------------------------------
% Build datastores
% -------------------------------------------------------------------------
dsTrain = combine(imdsTrain, pxdsTrain);
dsTrain = transform(dsTrain, @(d) augmentCometImage(d, augParams));

dsVal = combine(imdsVal, pxdsVal);
dsVal = transform(dsVal, @(d) { ...
    reshape(single(d{1}), size(d{1},1), size(d{1},2), 1), ...
    d{2}});

% -------------------------------------------------------------------------
% Training options from userOptions
% -------------------------------------------------------------------------
iterationsPerEpoch = max(1, floor(numTrainingImages / str2double(userOptions.MiniBatchSize)));

schedule = {warmupLearnRate(NumSteps=3, FrequencyUnit="epoch"), ...
            piecewiseLearnRate(DropFactor=0.5, ...
                               Period=50, ...
                               FrequencyUnit="iteration")};

% InitialLearnRate and L2Regularization are fixed: lower LR preserves pre-trained
% features; gradient threshold and regularization match expert training conditions.
if isdeployed
    plotsOpt = 'none';
else
    plotsOpt = 'training-progress';
end

options = trainingOptions('adam', ...
    LearnRateSchedule     = schedule, ...
    InitialLearnRate      = str2double(userOptions.InitialLearnRate), ...
    L2Regularization      = 1e-4, ...
    GradientThreshold     = 1.0, ...
    ValidationData        = dsVal, ...
    MaxEpochs             = str2double(userOptions.MaxEpoch), ...
    MiniBatchSize         = str2double(userOptions.MiniBatchSize), ...
    Shuffle               = 'every-epoch', ...
    CheckpointPath        = tempdir, ...
    VerboseFrequency      = 10, ...
    ExecutionEnvironment  = userOptions.ExecutionEnvironment, ...
    Plots                 = plotsOpt, ...
    Verbose               = true, ...
    ValidationFrequency   = iterationsPerEpoch, ...
    ValidationPatience    = str2double(userOptions.ValidationPatience));

% -------------------------------------------------------------------------
% Progress dialog
% -------------------------------------------------------------------------
progressDLG.Counter   = 0;
progressDLG.figHandle = helpdlg('Fine-tuning in progress. Please wait...', 'Training');

% -------------------------------------------------------------------------
% Fine-tune
% -------------------------------------------------------------------------
try
    [net, ~] = trainnet(dsTrain, net, lossFunc, options);

    if isvalid(progressDLG.figHandle)
        close(progressDLG.figHandle)
    end

    % --- Evaluate on test set ---
    fprintf('Evaluating on test set...\n');
    stride  = patchSize / 2;
    numTest = numel(imdsTest.Files);
    iouAll  = zeros(numTest, numClasses);

    for i = 1:numTest
        Itest      = readimage(imdsTest, i);
        gtMask     = readimage(pxdsTest, i);
        predMask   = semanticsegPatch(Itest, net, classNames, patchSize, stride);
        iouAll(i,:) = jaccard(predMask, gtMask)';
    end

    testIoU = mean(iouAll, 1, 'omitnan');
    fprintf('Test IoU — Head: %.3f  Tail: %.3f  Background: %.3f  Mean: %.3f\n', ...
        testIoU(1), testIoU(2), testIoU(3), mean(testIoU));

    % --- Visual check on random test sample ---
    idx = randi(numTest);
    I   = readimage(imdsTest, idx);
    C   = semanticsegPatch(I, net, classNames, patchSize, stride);
    B   = labeloverlay(I, C, 'Colormap', cmap, 'Transparency', 0.4);

    figure('Name', 'Fine-tuned model — test sample')
    imshow(B)
    pixelLabelColorbar(cmap, classNames)
    title(sprintf('Test sample — Mean IoU: %.3f', mean(testIoU)))

    % --- Save model ---
    if ~exist(outputPath, 'dir'), mkdir(outputPath); end
    timestamp  = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    modelName  = fullfile(outputPath, ...
        [timestamp, '_userModel_mIoU', sprintf('%.3f', mean(testIoU)), '.mat']);

    trainingParams.patchSize             = patchSize;
    trainingParams.encoderDepth          = encoderDepth;
    trainingParams.initialLR             = str2double(userOptions.InitialLearnRate);
    trainingParams.maxEpochs             = str2double(userOptions.MaxEpoch);
    trainingParams.preTrainedModelPath   = preTrainedModelPath;

    save(modelName, 'net', 'classNames', 'imageSize', ...
         'patchSize', 'testIoU', 'trainingParams')
    
    savedModelPath = modelName;
    
    helpdlg(['Model saved: ', modelName], 'Training complete')
    message = {'Fine-tuning complete.'; ''; ...
               ['Model saved to: ', modelName]};

catch me
    if isvalid(progressDLG.figHandle)
        close(progressDLG.figHandle)
    end
    dlgHandle = msgbox(me.message, 'Training error', 'error');
    uiwait(dlgHandle)
    message = {me.message};
    clear progressDLG
    return
end

clear progressDLG
bool = 1;
end

% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function img = readPatchImage(filename)
img = imread(filename);
img = single(img);
if max(img(:)) > 1
    img = img / 255;
end
img = reshape(img, size(img,1), size(img,2), 1);
end

% -------------------------------------------------------------------------
function loss = combinedLoss(Y, T, dw, cw)
epsilon = 1e-6;
Ys = stripdims(Y);
Ts = stripdims(T);

intersection = sum(Ys .* Ts, [1 2]);
denominator  = sum(Ys, [1 2]) + sum(Ts, [1 2]);
dicePerClass = 1 - (2 * intersection + epsilon) ./ (denominator + epsilon);
diceLossVal  = mean(dicePerClass, 'all');

if ndims(Ys) == 4
    dataFormat = 'SSCB';
else
    dataFormat = 'SSC';
end

ceSum  = crossentropy(Ys, Ts, 'DataFormat', dataFormat, 'Reduction', 'sum');
ceLoss = ceSum / (size(Ys,1) * size(Ys,2) * max(1, size(Ys,4)));

loss = dw * diceLossVal + cw * ceLoss;
end