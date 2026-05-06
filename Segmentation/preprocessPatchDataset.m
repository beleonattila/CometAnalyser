function preprocessPatchDataset(inputPath, outputPath, options)
% AUTHOR: Attila Beleon
% DATE: April 29, 2026
% NAME: preprocessPatchDataset (version 1.0)
%
% Extracts fixed-size patches from full-resolution comet assay images
% and saves them to disk for fast repeated training.
%
% Foreground oversampling (nnU-Net style): a configurable fraction of
% patches are centered on foreground pixels (Head or Tail) to counteract
% the extreme class imbalance (~94% Background) in comet assay images.
%
% INPUT:
%   inputPath   Path to dataset folder containing:
%                   Images/ — grayscale single-precision TIFF files
%                   Masks/  — uint8 PNG label files (255=Head,127=Tail,0=Bg)
%
%   outputPath  Path where patch dataset will be written:
%                   Images/ — patch TIFF files
%                   Masks/  — patch PNG files
%
%   options     Struct with fields (all optional, defaults shown):
%       .patchSize          [512 512]   Patch height and width
%       .patchesPerImage    10          Total patches extracted per image
%       .foregroundProb     0.5         Fraction of patches centered on
%                                       foreground pixels (Head or Tail)
%       .backgroundLabelID  0           Pixel value of Background class
%       .minForegroundPx    10          Min foreground pixels required to
%                                       accept a foreground-centered patch
%       .rngSeed            42          Random seed for reproducibility
%       .verbose            true        Print progress to console
%
% OUTPUT:
%   Patches written to outputPath/Images/ and outputPath/Masks/
%   Metadata saved to outputPath/patchMetadata.mat
%
% NOTES:
%   - Images must be single-precision TIFF in [0,1] range
%   - Masks must be uint8 PNG with values 255 (Head), 127 (Tail), 0 (Bg)
%   - Run once per dataset before training
%   - Patches near image borders are padded with replicate padding
%
% EXAMPLE:
%   opts.patchSize       = [512 512];
%   opts.patchesPerImage = 10;
%   opts.foregroundProb  = 0.5;
%   preprocessPatchDataset('data/raw', 'data/patches', opts);

% -------------------------------------------------------------------------
% Parse and validate options
% -------------------------------------------------------------------------
if nargin < 3
    options = struct();
end

patchSize       = getOption(options, 'patchSize',         [512 512]);
patchesPerImage = getOption(options, 'patchesPerImage',   10);
foregroundProb  = getOption(options, 'foregroundProb',    0.5);
bgLabelID       = getOption(options, 'backgroundLabelID', 0);
minFgPx         = getOption(options, 'minForegroundPx',   10);
rngSeed         = getOption(options, 'rngSeed',           42);
verbose         = getOption(options, 'verbose',           true);

rng(rngSeed);

pH = patchSize(1);
pW = patchSize(2);

% -------------------------------------------------------------------------
% Validate input folder structure
% -------------------------------------------------------------------------
imgDir  = fullfile(inputPath,  'Images');
mskDir  = fullfile(inputPath,  'Masks');
outImgDir = fullfile(outputPath, 'Images');
outMskDir = fullfile(outputPath, 'Masks');

assert(exist(imgDir,  'dir') == 7, 'Images/ subfolder not found in inputPath');
assert(exist(mskDir,  'dir') == 7, 'Masks/ subfolder not found in inputPath');

imgFiles = dir(fullfile(imgDir, '*.tif'));
mskFiles = dir(fullfile(mskDir, '*.png'));

assert(~isempty(imgFiles), 'No .tif files found in Images/');
assert(~isempty(mskFiles), 'No .png files found in Masks/');
assert(numel(imgFiles) == numel(mskFiles), ...
    'Number of images (%d) does not match number of masks (%d)', ...
    numel(imgFiles), numel(mskFiles));

% Verify filename pairing
for i = 1:numel(imgFiles)
    [~, imgName] = fileparts(imgFiles(i).name);
    [~, mskName] = fileparts(mskFiles(i).name);
    assert(strcmp(imgName, mskName), ...
        'Filename mismatch at index %d: image=%s mask=%s', ...
        i, imgFiles(i).name, mskFiles(i).name);
end

% -------------------------------------------------------------------------
% Create output directories
% -------------------------------------------------------------------------
if ~exist(outImgDir, 'dir'), mkdir(outImgDir); end
if ~exist(outMskDir, 'dir'), mkdir(outMskDir); end

% -------------------------------------------------------------------------
% Patch extraction loop
% -------------------------------------------------------------------------
numImages      = numel(imgFiles);
numFgPatches   = round(patchesPerImage * foregroundProb);
numBgPatches   = patchesPerImage - numFgPatches;
totalPatches   = numImages * patchesPerImage;
patchCount     = 0;

% Metadata for logging and reproducibility
metadata.patchSize       = patchSize;
metadata.patchesPerImage = patchesPerImage;
metadata.foregroundProb  = foregroundProb;
metadata.rngSeed         = rngSeed;
metadata.sourceImages    = {imgFiles.name}';
metadata.patchIndex      = [];  % filled below

if verbose
    fprintf('preprocessPatchDataset: extracting %d patches from %d images\n', ...
        totalPatches, numImages);
    fprintf('  Patch size:          %d x %d\n', pH, pW);
    fprintf('  Patches per image:   %d (%d foreground, %d random)\n', ...
        patchesPerImage, numFgPatches, numBgPatches);
    fprintf('  Foreground prob:     %.2f\n', foregroundProb);
    fprintf('  Output path:         %s\n\n', outputPath);
end

for i = 1:numImages
    % Load image and mask
    imgPath = fullfile(imgFiles(i).folder, imgFiles(i).name);
    mskPath = fullfile(mskFiles(i).folder, mskFiles(i).name);

    img = imread(imgPath);   % single [H x W]
    msk = imread(mskPath);   % uint8 [H x W], values 0/127/255

    img = single(img);
    if max(img(:)) > 1
        img = img / 255;
    end

    [H, W] = size(img);

    % Pad image and mask if smaller than patch size
    padH = max(0, pH - H);
    padW = max(0, pW - W);
    if padH > 0 || padW > 0
        img = padarray(img, [ceil(padH/2) ceil(padW/2)], 'replicate', 'both');
        msk = padarray(msk, [ceil(padH/2) ceil(padW/2)], bgLabelID,   'both');
        [H, W] = size(img);
        if verbose
            fprintf('  [WARNING] Image %s padded to %dx%d\n', imgFiles(i).name, H, W);
        end
    end

    % Find foreground pixel locations (Head=255, Tail=127)
    fgMask = msk > bgLabelID;
    [fgRows, fgCols] = find(fgMask);
    hasForeground = numel(fgRows) >= minFgPx;

    [~, baseName] = fileparts(imgFiles(i).name);

    % --- Extract foreground-centered patches ---
    fgExtracted = 0;
    fgAttempts  = 0;
    maxAttempts = numFgPatches * 10;  % avoid infinite loop

    while fgExtracted < numFgPatches && fgAttempts < maxAttempts
        fgAttempts = fgAttempts + 1;

        if hasForeground
            % Pick random foreground pixel as patch center
            idx     = randi(numel(fgRows));
            centerR = fgRows(idx);
            centerC = fgCols(idx);
        else
            % No foreground — fall back to random center
            centerR = randi([ceil(pH/2), H - floor(pH/2)]);
            centerC = randi([ceil(pW/2), W - floor(pW/2)]);
        end

        % Compute patch bounds centered on chosen pixel
        r1 = centerR - floor(pH/2);
        c1 = centerC - floor(pW/2);

        % Clamp to valid range — preserves full patch size
        r1 = max(1, min(r1, H - pH + 1));
        r2 = r1 + pH - 1;
        c1 = max(1, min(c1, W - pW + 1));
        c2 = c1 + pW - 1;

        % Safety check (unreachable after padding, kept as guard)
        if r1 < 1 || r2 > H || c1 < 1 || c2 > W
            continue
        end

        patchImg = img(r1:r2, c1:c2);
        patchMsk = msk(r1:r2, c1:c2);

        % Verify patch contains enough foreground
        if hasForeground && sum(patchMsk(:) > bgLabelID) < minFgPx
            continue
        end

        % Save patch
        patchCount   = patchCount + 1;
        fgExtracted  = fgExtracted + 1;
        patchName    = sprintf('%s_fg_%04d', baseName, fgExtracted);

        savePatch(patchImg, patchMsk, patchName, outImgDir, outMskDir);

        metadata.patchIndex(end+1).name   = patchName;
        metadata.patchIndex(end).source   = imgFiles(i).name;
        metadata.patchIndex(end).type     = 'foreground';
        metadata.patchIndex(end).bounds   = [r1 r2 c1 c2];
    end

    % If foreground extraction fell short (no foreground in image), fill with random
    remaining = patchesPerImage - fgExtracted;

    % --- Extract random patches ---
    for j = 1:remaining
        r1 = randi([1, max(1, H - pH + 1)]);
        r2 = r1 + pH - 1;
        c1 = randi([1, max(1, W - pW + 1)]);
        c2 = c1 + pW - 1;

        % Clamp
        r2 = min(r2, H);
        c2 = min(c2, W);

        patchImg = img(r1:r2, c1:c2);
        patchMsk = msk(r1:r2, c1:c2);

        patchCount   = patchCount + 1;
        patchName    = sprintf('%s_rnd_%04d', baseName, j);

        savePatch(patchImg, patchMsk, patchName, outImgDir, outMskDir);

        metadata.patchIndex(end+1).name   = patchName;
        metadata.patchIndex(end).source   = imgFiles(i).name;
        metadata.patchIndex(end).type     = 'random';
        metadata.patchIndex(end).bounds   = [r1 r2 c1 c2];
    end

    if verbose
        fprintf('  [%d/%d] %s — %d patches written (total: %d)\n', ...
            i, numImages, imgFiles(i).name, patchesPerImage, patchCount);
    end
end

% -------------------------------------------------------------------------
% Save metadata
% -------------------------------------------------------------------------
metadataPath = fullfile(outputPath, 'patchMetadata.mat');
save(metadataPath, 'metadata');

if verbose
    fprintf('\nDone. %d patches written to: %s\n', patchCount, outputPath);
    fprintf('Metadata saved to: %s\n', metadataPath);
end
end

% -------------------------------------------------------------------------
% Local helper: save one patch image and mask to disk
% -------------------------------------------------------------------------
function savePatch(patchImg, patchMsk, name, outImgDir, outMskDir)
% Image — single precision TIFF
imgPath = fullfile(outImgDir, [name, '.tif']);
t = Tiff(imgPath, 'w');
t.setTag('Photometric',         Tiff.Photometric.MinIsBlack);
t.setTag('ImageLength',         size(patchImg, 1));
t.setTag('ImageWidth',          size(patchImg, 2));
t.setTag('BitsPerSample',       32);
t.setTag('SampleFormat',        Tiff.SampleFormat.IEEEFP);
t.setTag('SamplesPerPixel',     1);
t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
t.write(patchImg);
t.close();

% Mask — uint8 PNG (preserves label values 0/127/255)
mskPath = fullfile(outMskDir, [name, '.png']);
imwrite(patchMsk, mskPath);
end

% -------------------------------------------------------------------------
% Local helper: get option with default fallback
% -------------------------------------------------------------------------
function val = getOption(opts, field, default)
if isfield(opts, field)
    val = opts.(field);
else
    val = default;
end
end