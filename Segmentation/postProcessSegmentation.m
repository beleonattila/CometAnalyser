function [segmentedComet, segmentedHead] = postProcessSegmentation(C8, Img, params)
% AUTHOR: Attila Beleon
% DATE: May 01, 2026
% NAME: postProcessSegmentation (version 1.0)
%
% Post-processes U-Net segmentation output:
%   1. Morphological cleanup (fill holes, remove small objects, close gaps)
%   2. Per-object segmentComet + segmentHead using existing pipeline
%
% Touching comets are not split automatically in this version.
% Users can split them manually using the existing click-to-select interface.
%
% Reuses segmentComet.m and segmentHead.m for consistency with manual
% segmentation pipeline.
%
% INPUT:
%   C8      uint8 [H x W] U-Net class index map
%               1 = Head, 2 = Tail, 3 = Background
%   Img     uint8 [H x W] original grayscale image
%   params  Struct with fields (all optional, defaults shown):
%               .minObjectSize          250
%               .closingRadius          20
%               .CometThAddFactor       0
%               .CometDiskDilation      0
%               .HeadThAddFactor        0
%               .HeadDiskDilation       0
%               .flag_ThresholdMode     1  (1=Otsu 2=Triangle 3=avg)
%               .flag_ThresholdHeadMode 1
%
% OUTPUT:
%   segmentedComet  uint8 [H x W]  comet mask (255=comet, 0=background)
%   segmentedHead   uint8 [H x W]  head mask  (255=head,  0=background)

% -------------------------------------------------------------------------
% Parse parameters with defaults
% -------------------------------------------------------------------------
minObjectSize  = getParam(params, 'minObjectSize',          250);
closingRadius  = getParam(params, 'closingRadius',          20);
CometThAdd     = getParam(params, 'CometThAddFactor',       0);
CometDiskDil   = getParam(params, 'CometDiskDilation',      0);
HeadThAdd      = getParam(params, 'HeadThAddFactor',        0);
HeadDiskDil    = getParam(params, 'HeadDiskDilation',       0);
thMode         = getParam(params, 'flag_ThresholdMode',     1);
thHeadMode     = getParam(params, 'flag_ThresholdHeadMode', 1);

% -------------------------------------------------------------------------
% Step 1: Build binary foreground mask
% Head(1) and Tail(2) are foreground, Background(3) is not
% -------------------------------------------------------------------------
BW = C8 > 0 & C8 < 3;

% -------------------------------------------------------------------------
% Step 2: Morphological cleanup
% -------------------------------------------------------------------------
BW = imfill(BW, 4, 'holes');
BW = bwareaopen(BW, minObjectSize, 4);

if closingRadius > 0
    se = strel('disk', closingRadius);
    BW = imclose(BW, se);
end

% Early exit if nothing remains after cleanup
if ~any(BW(:))
    segmentedComet = zeros(size(C8), 'uint8');
    segmentedHead  = zeros(size(C8), 'uint8');
    return
end

% -------------------------------------------------------------------------
% Step 3: Label individual connected objects
% Note: touching comets will appear as a single labeled object
% -------------------------------------------------------------------------
[labeled, numObjects] = bwlabel(BW, 4);

if numObjects == 0
    segmentedComet = zeros(size(C8), 'uint8');
    segmentedHead  = zeros(size(C8), 'uint8');
    return
end

% -------------------------------------------------------------------------
% Step 4: Per-object segmentation using existing pipeline
% -------------------------------------------------------------------------
segmentedComet = zeros(size(C8), 'uint8');
segmentedHead  = zeros(size(C8), 'uint8');

% Pre-filter image — same as ROI_processing.m
ImgFiltered = medfilt2(Img, [5 5], 'symmetric');
ImgFiltered = imgaussfilt(ImgFiltered, 1);

props = regionprops(labeled, 'BoundingBox');

for i = 1:numObjects
    bb    = props(i).BoundingBox;
    pad   = 30;
    H_img = size(C8, 1);
    W_img = size(C8, 2);

    r1 = max(1,     floor(bb(2)) - pad);
    r2 = min(H_img, floor(bb(2) + bb(4)) + pad);
    c1 = max(1,     floor(bb(1)) - pad);
    c2 = min(W_img, floor(bb(1) + bb(3)) + pad);

    ROIimg  = ImgFiltered(r1:r2, c1:c2);
    ROIsegm = uint8(labeled(r1:r2, c1:c2) == i);

    if ~any(ROIsegm(:))
        continue
    end

    [MaskComet, ~] = segmentComet(ROIimg, ROIsegm, ...
        CometThAdd, CometDiskDil, thMode);

    if ~any(MaskComet(:))
        continue
    end

    [MaskHead, ~] = segmentHead(ROIimg, MaskComet, ...
        HeadThAdd, HeadDiskDil, thHeadMode);

    % Write back to full image
    cometROI = segmentedComet(r1:r2, c1:c2);
    cometROI(MaskComet > 0) = 255;
    segmentedComet(r1:r2, c1:c2) = cometROI;

    if ~isempty(MaskHead) && any(MaskHead(:))
        headROI = segmentedHead(r1:r2, c1:c2);
        headROI(MaskHead > 0) = 255;
        segmentedHead(r1:r2, c1:c2) = headROI;
    end
end
end

% -------------------------------------------------------------------------
function val = getParam(params, field, default)
if isfield(params, field) && ~isempty(params.(field))
    val = params.(field);
else
    val = default;
end
end