function [bool, message] = autoSegmentClassical(app, method)
% AUTHOR: Attila Beleon
% DATE: May 01, 2026
% NAME: autoSegmentClassical (version 1.0)
%
% Classical automatic segmentation pipeline — no deep learning required.
%
% Pipeline:
%   1. Threshold full image using user-defined params (Otsu/Triangle/avg)
%   2. Watershed to separate touching blobs
%   3. Filter blobs by minimum head size → candidate head centroids
%   4. For each centroid, extract adaptive ROI and run segmentComet()
%      If mask touches ROI border → expand ROI and retry
%   5. Run segmentHead() on each accepted comet mask
%   6. Write results to Imgs_Stretched
%
% Adaptive ROI size is computed from average manually segmented object size.
% All threshold and dilation params come from existing app settings.
%
% INPUT:
%   app     App handles
%   method  'single' — segment current image only
%           'multi'  — segment all unannotated images
%
% OUTPUT:
%   bool    1 on success, 0 on failure
%   message Cell array of status/error messages

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
% Compute adaptive ROI size from manually segmented objects
% -------------------------------------------------------------------------
baseROIsize = computeAdaptiveROISize(app);

% -------------------------------------------------------------------------
% Read segmentation params from app settings
% -------------------------------------------------------------------------
thMode      = app.comet_handles.flag_ThresholdMode;
thHeadMode  = app.comet_handles.flag_ThresholdHeadMode;
CometThAdd  = app.comet_handles.CometThAddFactor;
CometDiskDil= app.comet_handles.CometSizeDiskDilation;
HeadThAdd   = app.comet_handles.HeadThAddFactor;
HeadDiskDil = app.comet_handles.HeadSizeDiskDilation;

% Minimum head size in pixels — filters noise from watershed output
minHeadSize = app.comet_handles.segmentationOptions.minObjectSize;

% -------------------------------------------------------------------------
% Segment images
% -------------------------------------------------------------------------
idx2          = find(idx);
numIm2Segment = numel(idx2);
wb = waitbar(0, 'Classical segmentation in progress. Please wait...');
for i = 1:numIm2Segment
    imgIdx = idx2(i);

    try
        % Get original and filtered image
        Img         = app.comet_handles.Imgs_Stretched(:,:,1,imgIdx);
        ImgFiltered = medfilt2(Img, [5 5], 'symmetric');
        ImgFiltered = imgaussfilt(ImgFiltered, 1);

        % --- Step 1: Threshold full image to find candidate objects ---
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

        BinThresh = thresh * 255 + HeadThAdd;
        BinThresh = max(0, min(255, BinThresh));
        thresh    = BinThresh / 255;

        BWfull = imbinarize(ImgFiltered, thresh);

        % --- Step 2: Label connected objects ---
        [labeled, numBlobs] = bwlabel(BWfull, 4);

        if numBlobs == 0
            continue
        end

        props    = regionprops(labeled, 'Area', 'Centroid');
        areas    = [props.Area];
        validIdx = find(areas >= minHeadSize);

        if isempty(validIdx)
            continue

        end

        % --- Step 3-4: Per-object adaptive ROI segmentation ---
        H_img = size(Img, 1);
        W_img = size(Img, 2);

        segmentedComet = zeros(size(Img), 'uint8');
        segmentedHead  = zeros(size(Img), 'uint8');

        for j = 1:numel(validIdx)
            blobIdx  = validIdx(j);
            centroid = props(blobIdx).Centroid;  % [col, row]
            cr       = round(centroid(2));        % row
            cc       = round(centroid(1));        % col

            % Adaptive ROI with border-touch retry
            roiSize    = baseROIsize;
            maxROIsize = min(H_img, W_img);
            accepted   = false;

            while roiSize <= maxROIsize
                % Extract ROI centered on centroid
                r1 = max(1,     cr - floor(roiSize/2));
                r2 = min(H_img, cr + floor(roiSize/2));
                c1 = max(1,     cc - floor(roiSize/2));
                c2 = min(W_img, cc + floor(roiSize/2));

                ROIimg  = ImgFiltered(r1:r2, c1:c2);

                % Build ROI seed mask from watershed blob
                ROIsegm = uint8(labeled(r1:r2, c1:c2) == blobIdx);

                % If seed not in ROI (edge case) — break
                if ~any(ROIsegm(:))
                    break
                end

                % Segment comet in ROI
                [MaskComet, ~] = segmentComet(ROIimg, ROIsegm, ...
                    CometThAdd, CometDiskDil, thMode);

                if ~any(MaskComet(:))
                    break
                end

                % Check if mask touches ROI border
                if touchesBorder(MaskComet)
                    % Expand ROI and retry
                    roiSize = round(roiSize * 1.5);
                    continue
                end

                % Mask accepted — segment head
                [MaskHead, ~] = segmentHead(ROIimg, MaskComet, ...
                    HeadThAdd, HeadDiskDil, thHeadMode);

                % Write comet mask to full image
                cometROI = segmentedComet(r1:r2, c1:c2);
                cometROI(MaskComet > 0) = 255;
                segmentedComet(r1:r2, c1:c2) = cometROI;

                % Write head mask to full image
                if ~isempty(MaskHead) && any(MaskHead(:))
                    headROI = segmentedHead(r1:r2, c1:c2);
                    headROI(MaskHead > 0) = 255;
                    segmentedHead(r1:r2, c1:c2) = headROI;
                end

                accepted = true;
                break
            end

            if ~accepted
                % Comet mask touched ROI border at maximum ROI size — object skipped.
            end
        end

        % Write results to app
        app.comet_handles.Imgs_Stretched(:,:,2,imgIdx) = segmentedComet;
        app.comet_handles.Imgs_Stretched(:,:,3,imgIdx) = segmentedHead;

    catch me
        fprintf('[WARNING] Image %d failed: %s\n', imgIdx, me.message);
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
bool = 1;
end

% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function roiSize = computeAdaptiveROISize(app)
% Compute base ROI size from average area of manually segmented objects.
% Falls back to fixed default if no manual segmentations exist.

defaultROI = 300;  % fallback if no manual segmentations exist

try
    allAreas = [];
    for i = 1:app.comet_handles.NumImages
        cometMask = app.comet_handles.Imgs_Stretched(:,:,2,i);
        if ~any(cometMask(:))
            continue
        end
        props    = regionprops(logical(cometMask), 'Area');
        areas    = [props.Area];
        allAreas = [allAreas, areas]; %#ok<AGROW>
    end

    if isempty(allAreas)
        roiSize = defaultROI;
        return
    end

    % Use average equivalent diameter as ROI size with 50% padding
    avgArea   = mean(allAreas);
    avgDiam   = 2 * sqrt(avgArea / pi);
    roiSize   = round(avgDiam * 1.5);

    % Clamp to sensible range
    roiSize = max(150, min(roiSize, 800));

catch
    roiSize = defaultROI;
end
end

% -------------------------------------------------------------------------
function result = touchesBorder(mask)
% Returns true if any foreground pixel touches the mask border
result = any(mask(1,:)) || any(mask(end,:)) || ...
         any(mask(:,1)) || any(mask(:,end));
end