function [bool, message] = autoSegmentClassical(app, method)
% AUTHOR: Attila Beleon
% DATE: May 01, 2026
% Updated: May 2026
% NAME: autoSegmentClassical (version 1.1)
%
% Classical automatic segmentation pipeline — no deep learning required.
%
% Pipeline:
%   1. Threshold full image using user-defined params
%   2. bwlabel to find candidate objects
%   3. Compute adaptive ROI size from current image object distribution
%   4. Filter by minimum object size
%   5. For each centroid, extract adaptive ROI and run segmentComet()
%      If mask touches ROI border → expand ROI × 1.5 and retry
%   6. Run segmentHead() on each accepted comet mask
%   7. Write results to Imgs_Stretched

bool    = 0;
message = [];

% -------------------------------------------------------------------------
% Determine which images to segment
% -------------------------------------------------------------------------
idx = false(app.comet_handles.NumImages, 1);

if strcmp(method, 'single')
    i = app.comet_handles.IndImgShown;
    if ~any(app.comet_handles.Imgs_Stretched(:,:,2,i), 'all')
        idx(i) = true;
    end
elseif strcmp(method, 'multi')
    for j = 1:app.comet_handles.NumImages
        if ~any(app.comet_handles.Imgs_Stretched(:,:,2,j), 'all')
            idx(j) = true;
        end
    end
end

if ~any(idx)
    if strcmp(method, 'single')
        message = {'The current image already contains annotations.'; ...
                   'Auto segmentation only runs on unannotated images.'};
    else
        message = {'No unannotated images found.'};
    end
    return
end

% -------------------------------------------------------------------------
% Read segmentation params from app settings
% -------------------------------------------------------------------------
thMode       = app.comet_handles.flag_ThresholdMode;
thHeadMode   = app.comet_handles.flag_ThresholdHeadMode;
CometThAdd   = app.comet_handles.CometThAddFactor;
CometDiskDil = app.comet_handles.CometSizeDiskDilation;
HeadThAdd    = app.comet_handles.HeadThAddFactor;
HeadDiskDil  = app.comet_handles.HeadSizeDiskDilation;
minObjectSize = app.comet_handles.segmentationOptions.minObjectSize;

% -------------------------------------------------------------------------
% Segment images
% -------------------------------------------------------------------------
idx2          = find(idx);
numIm2Segment = numel(idx2);
failedImages  = [];
wb = waitbar(0, 'Classical segmentation in progress. Please wait...');

for i = 1:numIm2Segment
    imgIdx = idx2(i);

    try
        % Load and filter image
        Img         = app.comet_handles.Imgs_Stretched(:,:,1,imgIdx);
        ImgFiltered = medfilt2(Img, [5 5], 'symmetric');
        ImgFiltered = imgaussfilt(ImgFiltered, 1);

        H_img = size(Img, 1);
        W_img = size(Img, 2);

        % --- Step 1: Threshold full image ---
        ImgFlat = ImgFiltered(:);

        if thMode == 1
            thresh = graythresh(ImgFlat);
        elseif thMode == 2
            [counts, binLocations] = imhist(ImgFlat);
            BinThresh = HistoTriangleThreshold(counts, 'Left', 'Right', 0);
            thresh = binLocations(BinThresh) / length(binLocations);
        else
            thOtsu = graythresh(ImgFlat);
            [counts, binLocations] = imhist(ImgFlat);
            BinThresh = HistoTriangleThreshold(counts, 'Left', 'Right', 0);
            thTri = binLocations(BinThresh) / length(binLocations);
            thresh = (thOtsu + thTri) / 2;
        end

        BinThresh = thresh * 255 + CometThAdd;
        BinThresh = max(0, min(255, BinThresh));
        thresh    = BinThresh / 255;
        BWfull    = imbinarize(ImgFiltered, thresh);

        % --- Step 2: Label connected objects ---
        [labeled, numBlobs] = bwlabel(BWfull, 4);

        if numBlobs == 0
            continue
        end

        % --- Step 3: Compute adaptive ROI size from this image ---
        % Use blob size distribution — median is robust to merged touching comets
        % Get oriented bounding box from blob properties
        props = regionprops(labeled, 'Area', 'Centroid', ...
                    'MajorAxisLength', 'MinorAxisLength', 'Orientation');
        
        areas    = [props.Area];

        % Filter to valid blobs only (above minimum size)
        validMask = areas >= minObjectSize;
        validIdx  = find(validMask);

        if isempty(validIdx)
            continue
        end

        validAreas = areas(validMask);

        % Median equivalent diameter → base ROI with 50% padding
        medianArea    = median(validAreas);
        medianDiam    = 2 * sqrt(medianArea / pi);
        baseROIsize   = round(medianDiam * 1.5);

        % Minimum ROI: must be at least 3× the side length of the
        % smallest valid object — ensures the smallest comet fits
        minObjSide    = sqrt(min(validAreas));
        minROIsize    = round(minObjSide * 3);

        % Clamp: minROIsize ≤ baseROIsize ≤ half the image short side
        maxROIsize    = round(min(H_img, W_img) * 0.75);
        baseROIsize   = max(minROIsize, min(baseROIsize, maxROIsize));


        % --- Step 4-5: Per-object adaptive ROI segmentation ---
        segmentedComet = zeros(size(Img), 'uint8');
        segmentedHead  = zeros(size(Img), 'uint8');

        for j = 1:numel(validIdx)
            blobIdx  = validIdx(j);
            centroid = props(blobIdx).Centroid;  % [col, row]
            cr       = round(centroid(2));
            cc       = round(centroid(1));

            % Use oriented extent to size the ROI
            % MajorAxisLength covers the full comet length (head + tail)
            % MinorAxisLength covers the width
            % Add padding proportional to the object size
            majorLen  = props(blobIdx).MajorAxisLength;
            minorLen  = props(blobIdx).MinorAxisLength;
            orient    = props(blobIdx).Orientation;  % degrees from horizontal

            % Padding: 30% of major axis or minROIsize, whichever is larger
            pad = max(round(majorLen * 2), minROIsize);

            % Project major axis unit vector onto row/col
            orientRad    = deg2rad(orient);
            majorUnitCol =  cos(orientRad);  % col component of major axis direction
            majorUnitRow = -sin(orientRad);  % row component (negative: image y is flipped)

            % Half-extents along major and minor axes with padding
            halfMajor = round(majorLen/2) + pad;
            halfMinor = round(minorLen/2) + pad;

            % Extent in row and col directions:
            % Major axis contributes along its projection
            % Minor axis contributes perpendicular to it
            halfRow = round(abs(halfMajor * majorUnitRow) + abs(halfMinor * majorUnitCol));
            halfCol = round(abs(halfMajor * majorUnitCol) + abs(halfMinor * majorUnitRow));

            % Extract ROI
            r1 = max(1,     cr - halfRow);
            r2 = min(H_img, cr + halfRow);
            c1 = max(1,     cc - halfCol);
            c2 = min(W_img, cc + halfCol);

            ROIimg  = ImgFiltered(r1:r2, c1:c2);
            ROIsegm = uint8(labeled(r1:r2, c1:c2) == blobIdx);

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

            % Write back
            cometROI = segmentedComet(r1:r2, c1:c2);
            cometROI(MaskComet > 0) = 255;
            segmentedComet(r1:r2, c1:c2) = cometROI;

            if ~isempty(MaskHead) && any(MaskHead(:))
                headROI = segmentedHead(r1:r2, c1:c2);
                headROI(MaskHead > 0) = 255;
                segmentedHead(r1:r2, c1:c2) = headROI;
            end
        end

        % Write results to app
        app.comet_handles.Imgs_Stretched(:,:,2,imgIdx) = segmentedComet;
        app.comet_handles.Imgs_Stretched(:,:,3,imgIdx) = segmentedHead;

    catch
        failedImages(end+1) = imgIdx;
    end

    if ishandle(wb)
        waitbar(i/numIm2Segment, wb, ...
            sprintf('Classical segmentation in progress...\n%d / %d', ...
                    i, numIm2Segment));
    end
end

if ishandle(wb), close(wb); end

message = {'Segmentation complete.'; ''; ...
           [num2str(numIm2Segment), ' image(s) processed.']};
if ~isempty(failedImages)
    failedList   = strjoin(arrayfun(@num2str, failedImages, 'UniformOutput', false), ', ');
    message{end+1} = '';
    message{end+1} = ['WARNING: ' num2str(numel(failedImages)) ' image(s) failed (index): ' failedList];
end
bool = 1;
end

% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function result = touchesBorder(mask)
result = any(mask(1,:)) || any(mask(end,:)) || ...
         any(mask(:,1)) || any(mask(:,end));
end