function [bool, message] = trainSemanticSegmentationModelExpert(patchPath, outputPath, expertOptions)
% AUTHOR: Attila Beleon
% DATE: April 29, 2026
% NAME: trainSemanticSegmentationModelExpert (version 1.0)
%
% Expert training pipeline for CometAnalyser U-Net segmentation model.
%
% Features:
%   - Patch-based training (512x512) with foreground oversampling
%   - K-fold cross validation (k determined by dataset size)
%   - Dice + Cross-Entropy combined loss
%   - Weight averaging across folds → single deployable model
%   - Full augmentation pipeline
%   - Sliding window inference for evaluation
%
% INPUT:
%   patchPath       Path to preprocessed patch dataset (Images/ + Masks/)
%   outputPath      Path where models and results will be saved
%   expertOptions   Struct with training hyperparameters (see defaults below)
%
% OUTPUT:
%   bool            1 on success, 0 on failure
%   message         Error message cell array if failed, empty otherwise
%
% USAGE:
%   opts.patchSize       = [512 512];
%   opts.encoderDepth    = 4;
%   opts.miniBatchSize   = 8;
%   opts.maxEpochs       = 30;
%   opts.initialLR       = 1e-4;
%   opts.l2Reg           = 1e-4;
%   opts.rngSeed         = 42;
%   opts.testFraction    = 0.15;
%   opts.diceWeight      = 0.7;
%   opts.ceWeight        = 0.3;
%   [bool, msg] = trainSemanticSegmentationModelExpert('data/patches', 'models/', opts);

bool    = 0;
message = [];

% -------------------------------------------------------------------------
% Parse expert options with defaults
% -------------------------------------------------------------------------
patchSize      = getOpt(expertOptions, 'patchSize',      [512 512]);
encoderDepth   = getOpt(expertOptions, 'encoderDepth',   4);
miniBatchSize  = getOpt(expertOptions, 'miniBatchSize',  8);
maxEpochs      = getOpt(expertOptions, 'maxEpochs',      30);
initialLR      = getOpt(expertOptions, 'initialLR',      1e-4);
l2Reg          = getOpt(expertOptions, 'l2Reg',          1e-4);
rngSeed        = getOpt(expertOptions, 'rngSeed',        42);
testFraction   = getOpt(expertOptions, 'testFraction',   0.15);
diceWeight     = getOpt(expertOptions, 'diceWeight',     0.7);
ceWeight       = getOpt(expertOptions, 'ceWeight',       0.3);
gradientThresh     = getOpt(expertOptions, 'gradientThresh',     1.0);
validationPatience = getOpt(expertOptions, 'validationPatience', 6);
averagingThreshold = getOpt(expertOptions, 'averagingThreshold', 0.05);

rng(rngSeed);

classNames = ["Head", "Tail", "Background"];
labelIDs   = [255 127 0];
numClasses = numel(classNames);
cmap       = [1 0 0; 0 0 1; 0 0 0];  % head=red tail=blue bg=black

% -------------------------------------------------------------------------
% Validate patch folder structure
% -------------------------------------------------------------------------
imgDir = fullfile(patchPath, 'Images');
mskDir = fullfile(patchPath, 'Masks');

if ~exist(imgDir, 'dir') || ~exist(mskDir, 'dir')
    message = {'Patch folder structure invalid.'; ...
               'Expected Images/ and Masks/ subfolders.'};
    return
end

imgFiles = dir(fullfile(imgDir, '*.tif'));
mskFiles = dir(fullfile(mskDir, '*.png'));

if isempty(imgFiles)
    message = {'No .tif patch files found in Images/.'};
    return
end

if numel(imgFiles) ~= numel(mskFiles)
    message = {sprintf('Image/mask count mismatch: %d images, %d masks.', ...
                numel(imgFiles), numel(mskFiles))};
    return
end

if numel(imgFiles) < 6
    message = {'Not enough patches for training (minimum 6).'};
    return
end

fprintf('Found %d patch pairs in: %s\n', numel(imgFiles), patchPath);

% -------------------------------------------------------------------------
% Build full datastores
% -------------------------------------------------------------------------
imds = imageDatastore(imgDir, ...
    'FileExtensions', '.tif', ...
    'ReadFcn', @readPatchImage);

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
title('Class distribution across patch dataset')

fprintf('Class frequencies:\n')
for i = 1:numClasses
    fprintf('  %-12s %.4f\n', classNames(i), frequency(i));
end

% -------------------------------------------------------------------------
% Verify image dimensions
% -------------------------------------------------------------------------
I = readimage(imds, 1);
[h, w, ~] = size(I);
reqDiv = 2^encoderDepth;

if mod(h, reqDiv) ~= 0 || mod(w, reqDiv) ~= 0
    message = {sprintf('Patch dimensions %dx%d not divisible by %d.', h, w, reqDiv)};
    return
end

imageSize = [h w];
fprintf('Patch size confirmed: %dx%d\n', h, w);

% -------------------------------------------------------------------------
% Held-out test set — fixed before any folding
% -------------------------------------------------------------------------
numPatches  = numel(imds.Files);
numTest     = max(1, round(testFraction * numPatches));
allIdx      = randperm(numPatches);
testIdx     = allIdx(1:numTest);
remainIdx   = allIdx(numTest+1:end);

imdsTest  = subset(imds, testIdx);
pxdsTest  = subset(pxds, testIdx);
imdsRemain = subset(imds, remainIdx);
pxdsRemain = subset(pxds, remainIdx);

fprintf('Test set: %d patches | Training pool: %d patches\n', ...
    numTest, numel(remainIdx));

% -------------------------------------------------------------------------
% Determine k for cross validation
% -------------------------------------------------------------------------
numRemain = numel(remainIdx);
k = determineKFolds(numRemain);
fprintf('K-fold: k=%d (dataset size=%d)\n\n', k, numRemain);

% -------------------------------------------------------------------------
% Loss function
% -------------------------------------------------------------------------
lossFunc = @(Y, T) combinedLoss(Y, T, diceWeight, ceWeight);

% -------------------------------------------------------------------------
% Augmentation parameters — from expertOptions, with sensible defaults
% -------------------------------------------------------------------------
if isfield(expertOptions, 'augParams')
    augParams = expertOptions.augParams;
else
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
end

% -------------------------------------------------------------------------
% Training schedule
% -------------------------------------------------------------------------
if expertOptions.useWarmup
    schedule = {warmupLearnRate(NumSteps=3, FrequencyUnit="epoch"), ...
                piecewiseLearnRate(DropFactor=0.5, Period=50, FrequencyUnit="iteration")};
else
    schedule = piecewiseLearnRate(DropFactor=0.5, Period=50, FrequencyUnit="iteration");
end

% -------------------------------------------------------------------------
% Create output directory
% -------------------------------------------------------------------------
if ~exist(outputPath, 'dir'), mkdir(outputPath); end
timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
runDir    = fullfile(outputPath, ['run_', timestamp]);
mkdir(runDir);
fprintf('Output directory: %s\n\n', runDir);

% -------------------------------------------------------------------------
% K-fold cross validation loop
% -------------------------------------------------------------------------
foldNets     = cell(k, 1);
foldMetrics  = zeros(k, 3);  % IoU per class per fold
foldIdx      = createKFoldIndices(numRemain, k);

for fold = 1:k
    fprintf('=== FOLD %d / %d ===\n', fold, k);

    % Split remaining data into train/val for this fold
    valFoldIdx   = foldIdx{fold};
    trainFoldIdx = cell2mat(foldIdx(setdiff(1:k, fold))');

    imdsFoldTrain = subset(imdsRemain, trainFoldIdx);
    imdsFoldVal   = subset(imdsRemain, valFoldIdx);
    pxdsFoldTrain = subset(pxdsRemain, trainFoldIdx);
    pxdsFoldVal   = subset(pxdsRemain, valFoldIdx);

    fprintf('  Train patches: %d | Val patches: %d\n', ...
        numel(trainFoldIdx), numel(valFoldIdx));

    % Build datastores
    dsFoldTrain = combine(imdsFoldTrain, pxdsFoldTrain);
    dsFoldTrain = transform(dsFoldTrain, @(d) augmentCometImage(d, augParams));
    dsFoldVal   = combine(imdsFoldVal,   pxdsFoldVal);

    
    if ~isempty(expertOptions.continueFromRun)
        foldPath = fullfile(expertOptions.continueFromRun, sprintf('fold_%02d_net.mat', fold));
        data = load(foldPath);
        net  = data.net;
        fprintf('  Resuming from: %s\n', foldPath);
        useLR = expertOptions.continueLR;
    else
        % Fresh network for each fold
        net   = unet(imageSize, numClasses, 'EncoderDepth', encoderDepth);
        useLR = expertOptions.initialLR;
    end

    iterationsPerEpoch = floor(numel(trainFoldIdx) / miniBatchSize);

    % Training options
    options = trainingOptions('adam', ...
        LearnRateSchedule    = schedule, ...
        InitialLearnRate     = useLR, ...
        L2Regularization     = l2Reg, ...
        GradientThreshold    = gradientThresh, ...
        ValidationData       = dsFoldVal, ...
        MaxEpochs            = maxEpochs, ...
        MiniBatchSize        = miniBatchSize, ...
        Shuffle              = 'every-epoch', ...
        CheckpointPath       = tempdir, ...
        VerboseFrequency     = 10, ...
        ExecutionEnvironment = 'auto', ...
        Plots                = 'training-progress', ...
        ValidationFrequency  = iterationsPerEpoch, ...
        ValidationPatience   = validationPatience);



    % Train
    try
        [net, trainInfo] = trainnet(dsFoldTrain, net, lossFunc, options);
    catch me
        fprintf('  [ERROR] Fold %d: %s\n', fold, me.message);
        if ~isempty(me.cause)
            fprintf('  Caused by: %s\n', me.cause{1}.message);
        end
        continue
    end

    % Save fold model
    foldModelPath = fullfile(runDir, sprintf('fold_%02d_net.mat', fold));
    save(foldModelPath, 'net', 'classNames', 'imageSize', 'patchSize');
    fprintf('  Fold model saved: %s\n', foldModelPath);

    % Evaluate fold on validation set
    fprintf('  Evaluating fold %d on validation set...\n', fold);
    foldIoU = evaluatePatchDatastore(imdsFoldVal, pxdsFoldVal, net, ...
                                     classNames, patchSize);
    foldMetrics(fold, :) = foldIoU;
    fprintf('  Val IoU — Head: %.3f  Tail: %.3f  Background: %.3f\n', ...
        foldIoU(1), foldIoU(2), foldIoU(3));

    foldNets{fold} = net;
end

% -------------------------------------------------------------------------
% Selective weight averaging across folds
% -------------------------------------------------------------------------
fprintf('\n=== Selective weight averaging across %d fold models ===\n', k);
netAvg = selectiveAverageFoldModels(foldNets, foldMetrics, averagingThreshold);

% -------------------------------------------------------------------------
% Evaluate averaged model on held-out test set
% -------------------------------------------------------------------------
fprintf('Evaluating averaged model on held-out test set...\n');
testIoU = evaluatePatchDatastore(imdsTest, pxdsTest, netAvg, ...
                                  classNames, patchSize);

fprintf('Test IoU — Head: %.3f  Tail: %.3f  Background: %.3f\n', ...
    testIoU(1), testIoU(2), testIoU(3));
fprintf('Mean IoU: %.3f\n', mean(testIoU));

% -------------------------------------------------------------------------
% Visual evaluation on random test samples
% -------------------------------------------------------------------------
numVis = min(3, numel(imdsTest.Files));
for v = 1:numVis
    I   = readimage(imdsTest, v);
    C   = semanticsegPatch(I, netAvg, classNames, patchSize, round(patchSize/2));
    B   = labeloverlay(I, C, 'Colormap', cmap, 'Transparency', 0.4);

    figure('Name', sprintf('Test sample %d', v))
    imshow(B)
    pixelLabelColorbar(cmap, classNames)
    title(sprintf('Test sample %d — averaged model', v))
end

% -------------------------------------------------------------------------
% Save final averaged model and metadata
% -------------------------------------------------------------------------
finalModelPath = fullfile(runDir, [timestamp, '_finalModel_mIoU', ...
    sprintf('%.3f', mean(testIoU)), '.mat']);

trainingParams.patchSize      = patchSize;
trainingParams.encoderDepth   = encoderDepth;
trainingParams.miniBatchSize  = miniBatchSize;
trainingParams.maxEpochs      = maxEpochs;
trainingParams.initialLR      = useLR;
trainingParams.l2Reg          = l2Reg;
trainingParams.rngSeed        = rngSeed;
trainingParams.diceWeight     = diceWeight;
trainingParams.ceWeight       = ceWeight;
trainingParams.kFolds         = k;
trainingParams.testFraction   = testFraction;

save(finalModelPath, 'netAvg', 'classNames', 'imageSize', ...
    'patchSize', 'foldMetrics', 'testIoU', 'trainingParams');

fprintf('\nFinal model saved: %s\n', finalModelPath);

bool = 1;
end

% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function img = readPatchImage(filename)
% Load single-precision TIFF patch and ensure [H x W x 1] single
img = imread(filename);
img = single(img);
if max(img(:)) > 1
    img = img / 255;
end
img = reshape(img, size(img,1), size(img,2), 1);
end

% -------------------------------------------------------------------------
function k = determineKFolds(numSamples)
if numSamples < 20
    k = numSamples;       % leave-one-out
elseif numSamples < 50
    k = 5;
elseif numSamples < 100
    k = 10;
else
    k = 5;
end
end

% -------------------------------------------------------------------------
function foldIdx = createKFoldIndices(numSamples, k)
% Returns cell array of length k, each cell contains indices for that fold
shuffled = randperm(numSamples);
foldIdx  = cell(k, 1);
foldSize = floor(numSamples / k);
remainder = numSamples - foldSize * k;

start = 1;
for i = 1:k
    extra   = (i <= remainder);  % distribute remainder across first folds
    len     = foldSize + extra;
    foldIdx{i} = shuffled(start:start+len-1);
    start   = start + len;
end
end

% -------------------------------------------------------------------------
function netAvg = selectiveAverageFoldModels(foldNets, foldMetrics, threshold)
% Only average folds within threshold of best fold mean IoU.
% foldMetrics is k×numClasses; failed folds have zeros (excluded by threshold).
validMask = ~cellfun(@isempty, foldNets);
validNets = foldNets(validMask);
k = numel(validNets);
if k == 0, error('No valid fold models.'); end
if k == 1, netAvg = validNets{1}; return; end

meanIoU  = mean(foldMetrics(validMask, :), 2, 'omitnan');
bestIoU  = max(meanIoU);
eligible = meanIoU >= (bestIoU - threshold);
eligibleNets = validNets(eligible);

fprintf('Selective averaging: %d/%d folds eligible\n', numel(eligibleNets), k);

if numel(eligibleNets) == 1
    netAvg = eligibleNets{1};
    return
end

netAvg = eligibleNets{1};
n = numel(eligibleNets);
for i = 2:n
    for j = 1:height(netAvg.Learnables)
        netAvg.Learnables.Value{j} = ...
            netAvg.Learnables.Value{j} * ((i-1)/i) + ...
            eligibleNets{i}.Learnables.Value{j} * (1/i);
    end
end
fprintf('Averaged %d eligible fold models.\n', n);
end

% -------------------------------------------------------------------------
function iouPerClass = evaluatePatchDatastore(imds, pxds, net, classNames, patchSize)
% Compute mean IoU per class over a datastore using sliding window inference
stride     = round(patchSize / 2);
numImages  = numel(imds.Files);
numClasses = numel(classNames);
iouAll     = zeros(numImages, numClasses);

for i = 1:numImages
    I            = readimage(imds, i);
    gtMask       = readimage(pxds, i);
    predMask     = semanticsegPatch(I, net, classNames, patchSize, stride);
    iouAll(i,:)  = jaccard(predMask, gtMask)';
end

iouPerClass = mean(iouAll, 1, 'omitnan');
end

% -------------------------------------------------------------------------
function val = getOpt(opts, field, default)
if isfield(opts, field)
    val = opts.(field);
else
    val = default;
end
end

% -------------------------------------------------------------------------
function loss = combinedLoss(Y, T, dw, cw)
    epsilon = 1e-6;

    Ys = stripdims(Y);
    Ts = stripdims(T);

    % Sum over spatial dimensions [1 2], keep class [3] and batch [4]
    intersection = sum(Ys .* Ts, [1 2]);
    denominator  = sum(Ys, [1 2]) + sum(Ts, [1 2]);
    dicePerClass = 1 - (2 * intersection + epsilon) ./ (denominator + epsilon);
    diceLossVal  = mean(dicePerClass, 'all');

    % CE — format depends on whether batch dim exists
    if ndims(Ys) == 4
        dataFormat = 'SSCB';
    else
        dataFormat = 'SSC';
    end

    ceSum  = crossentropy(Ys, Ts, 'DataFormat', dataFormat, 'Reduction', 'sum');
    ceLoss = ceSum / (size(Ys,1) * size(Ys,2) * size(Ys,4));

    loss = dw * diceLossVal + cw * ceLoss;
end