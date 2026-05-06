function data = augmentCometImage(data, params)
% AUTHOR: Attila Beleon
% DATE: April 28, 2026
% Updated: April 29, 2026
% NAME: augmentCometImage (version 2.0)
%
% Applies stochastic augmentations to image+mask pairs for comet assay
% microscopy images. Merges approaches from augmentImageAndLabel v1.0
% (Piccinini & Beleon, 2022) with extended photometric augmentations.
%
% Geometric augmentations: applied to both image and mask.
% Photometric augmentations: applied to image only.
%
% INPUT:
%   data    Cell {img, mask}
%               img  - [H x W x 1] single [0,1] grayscale
%               mask - categorical [H x W]
%   params  Struct — see augParams in trainSemanticSegmentationModel
%
% OUTPUT:
%   data    Augmented {img, mask}

img  = single(data{1});
mask = data{2};

% Normalize to [0,1] if loaded outside expected range
if max(img(:)) > 1
    img = img / 255;
end

% -------------------------------------------------------------------------
% GEOMETRIC — applied to both image and mask
% -------------------------------------------------------------------------

% 1. Random horizontal flip
if params.doFlip && rand > 0.5
    img  = fliplr(img);
    mask = fliplr(mask);
end

% 2. Random vertical flip
if params.doFlip && rand > 0.5
    img  = flipud(img);
    mask = flipud(mask);
end

% 3. Random affine: rotation, translation, scale
tform      = randomAffine2d( ...
    'XTranslation', params.xTrans, ...
    'YTranslation', params.yTrans, ...
    'Rotation',     params.rotVector, ...
    'Scale',        params.scaleVector);
outputView = affineOutputView(size(img), tform, 'BoundsStyle', 'centerOutput');

img      = imwarp(img, tform, 'OutputView', outputView, ...
               'InterpolationMethod', 'linear');

% imwarp cannot handle categorical — convert to uint8, warp, restore
maskUint = uint8(mask) - 1;  % 1-based categorical → 0-based: Head=0 Tail=1 Bg=2
maskUint = imwarp(maskUint, tform, 'OutputView', outputView, ...
               'InterpolationMethod', 'nearest', ...
               'FillValues', 2);  % fill border with Background
mask     = categorical(maskUint, [0 1 2], ["Head" "Tail" "Background"]);

% -------------------------------------------------------------------------
% PHOTOMETRIC — applied to image only
% -------------------------------------------------------------------------

% 4. Intensity augmentation — three modes selected randomly
%    Mode 1: multiplicative scaling (standard)
%    Mode 2: additive median-based shift (from augmentImageAndLabel v1.0)
%    Mode 3: no intensity change
intensityMode = randi(3);
switch intensityMode
    case 1  % multiplicative
        scale = params.intensityRange(1) + diff(params.intensityRange) * rand;
        img   = img * scale;
    case 2  % additive median shift
        medianInt = median(img(:));
        shift     = medianInt * (params.intensityRange(1) + ...
                    diff(params.intensityRange) * rand);
        img = img + shift;
end

% 5. Gamma correction
gamma = params.gammaRange(1) + diff(params.gammaRange) * rand;
img   = img .^ gamma;

% 6. Noise — three types from augmentImageAndLabel v1.0, selected randomly
if params.maxNoiseStd > 0
    noiseType = randi(4);  % 1=none, 2=gaussian, 3=poisson, 4=speckle
    switch noiseType
        case 2
            noiseStd = params.maxNoiseStd * rand;
            img = img + noiseStd * randn(size(img), 'single');
        case 3
            img = single(imnoise(img, 'poisson'));
        case 4
            img = single(imnoise(img, 'speckle'));
    end
end

% 7. Gaussian blur — 50% probability
if params.maxBlurSigma > 0 && rand > 0.5
    sigma = params.maxBlurSigma * rand;
    img   = imgaussfilt(img, sigma);
end

% 8. Vignetting simulation — 50% probability
if params.vignetteStrength > 0 && rand > 0.5
    [h, w, ~] = size(img);
    [X, Y]    = meshgrid(linspace(-1,1,w), linspace(-1,1,h));
    R         = sqrt(X.^2 + Y.^2);
    strength  = params.vignetteStrength * rand;
    vignette  = single(1 - strength * R.^2);
    img       = img .* vignette;
end

% Clamp to valid range
img = max(0, min(1, img));

data{1} = img;
data{2} = mask;
end