function [bool, errorString] = ROI_processing(app, BB, BWout1, cometProp)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 20, 2021
% NAME: ROI_processing (version 1.0)
% 
% Calculating the required data for app.comet_handles.Roi and .masks
% properties, updating the scope image with the result.
%
% INPUT:
%   app                 Handles of the application.
% 	BB                  Bounding box of selected comet to show in scope
%   BWout1              Binary mask image of selected comet
%   cometProp           TODO
%
% OUTPUT:
%   bool                Succes indicator bool
%   errorString         Error message if something goes wrong
%
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

errorString = [];
bool = 0;
IndImgShown = app.comet_handles.IndImgShown;
ImgShown = app.comet_handles.Imgs_Stretched(:,:,1,IndImgShown);

ROIori = ImgShown(BB(1,1):BB(2,1),BB(2,2):BB(1,2));
if all(ROIori(:)==0) || all(ROIori(:)==255)
    bool = 0;
    errorString = {'No comet was found in the region.'};
    return
end

ImgShownFiltered = medfilt2(ImgShown, [5, 5], 'symmetric');
h = fspecial('average', 3);
ImgShownFiltered = imfilter(ImgShownFiltered, h, 'symmetric');
ROIoriFiltered = ImgShownFiltered(BB(1,1):BB(2,1),BB(2,2):BB(1,2));
flag_CurrentCometType = app.comet_handles.flag_CurrentCometType;
flag_CometFitFreehand = app.comet_handles.flag_CometFitFreehand;
% Segment comet
MaskHead = [];
if isempty(cometProp)
    ROIsegm = BWout1(BB(1,1):BB(2,1),BB(2,2):BB(1,2));
    if flag_CometFitFreehand == 1
        [MaskComet, ~] = segmentComet(ROIoriFiltered, ROIsegm, 0, 0, 0);
    else
        [MaskComet, ~] = segmentComet(ROIoriFiltered, ROIsegm, app.comet_handles.CometThAddFactor, app.comet_handles.CometSizeDiskDilation, app.comet_handles.flag_ThresholdMode);
    end
    if flag_CurrentCometType == 1
        MaskHead = MaskComet;
    end
    
    % If comet head present (3 = Present tail and head)
    if flag_CurrentCometType == 3
        [MaskHead, ~] = segmentHead(ROIoriFiltered, MaskComet, app.comet_handles.HeadThAddFactor, app.comet_handles.HeadSizeDiskDilation, app.comet_handles.flag_ThresholdHeadMode);
    end
    
    % To delete external pixels in case of perfect fit.
    if flag_CometFitFreehand == 1
        if ~isempty(MaskHead)
            MaskHead(ROIsegm==0)=0;
        end
        if ~isempty(MaskComet)
            MaskComet(ROIsegm==0)=0;
        end
    end
    
    % At this point the mask is ready. Next step is to check wether a class
    % ID is already there ot not.
    classLayer = app.comet_handles.Imgs_Composed(BB(1,1):BB(2,1),BB(2,2):BB(1,2), 4, IndImgShown);
    classIdx = unique(classLayer(logical(MaskComet)));
    classIdx = classIdx(classIdx>0);
    
else % The selected comet have been segmented and classified already.
    
    % Calclating an enlarged bounding box
    xRadius = floor(BB(2,1) - BB(1,1));
    yRadius = floor(BB(1,2) - BB(2,2));
    [w, h, ~] = size(app.comet_handles.Imgs_Composed(:,:, 1, IndImgShown));
    
    xL = max(1,BB(1,1)-xRadius);
    xH = min(w,BB(2,1)+xRadius);
    yL = max(1,BB(2,2)-yRadius);
    yH = min(h,BB(1,2)+yRadius);
    
    BB2 = [xL, yH;... % This is the enlarged Bounding box
           xH, yL];
    
    ROIori = ImgShown(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2));
    ROIoriFiltered = ImgShownFiltered(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2));
    fakeIm = uint8(zeros(w, h));
    fakeIm(BB(1,1):BB(2,1),BB(2,2):BB(1,2)) = uint8(cometProp.mask);
    MaskComet = fakeIm(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2));
    MaskHead = app.comet_handles.Imgs_Composed(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2), 3, IndImgShown);
    MaskHead = MaskHead .* MaskComet;
    MaskHead(MaskHead<255) = 0;
    MaskHead(MaskHead == 255) = 1;
    SE = strel('rectangle',[xRadius, yRadius]);
    ROIsegm = imdilate(MaskComet, SE);
    classIdx = [];
end

if length(classIdx) == 1
    classNames = fieldnames(app.comet_handles.Classes);
    [maskRow, maskCol] = find(MaskComet==1);
    maskCenterCoor = round([((min(maskRow) + max(maskRow))/2)+BB(1,1), ((min(maskCol) + max(maskCol))/2)+BB(2,2)]);
    membersOnThisImage = app.comet_handles.Classes.(classNames{classIdx}).Members([app.comet_handles.Classes.(classNames{classIdx}).Members.ImID] == IndImgShown);
    idToShow = [];
    for thumbIterator = 1:size(membersOnThisImage,2)
        currentThumbcoor = membersOnThisImage(thumbIterator).thumbnailCoor;
        if currentThumbcoor(1, 1) < maskCenterCoor(1) && currentThumbcoor(2, 1) > maskCenterCoor(1) &&...
                currentThumbcoor(2, 2) < maskCenterCoor(2) && currentThumbcoor(1, 2) > maskCenterCoor(2)
            if isempty(idToShow)
                idToShow = thumbIterator;
            else
                errorString = {'Selected coordinates have been found stored as coordinates of multipe class members!';...
                                'Please contact the developer!'};
                bool = 0;
                return
            end
        end
    end
    if ~isempty(idToShow)
        coorToShow = membersOnThisImage(idToShow).thumbnailCoor;
        ROIcomposed = app.comet_handles.Imgs_Composed(coorToShow(1,1):coorToShow(2,1),coorToShow(2,2):coorToShow(1,2),1:3,IndImgShown);
        app.selectedComet.className = classNames{classIdx};
        app.selectedComet.param = membersOnThisImage(idToShow);
    else
        errorString = {'The selected region might touch a classified object. Please select another region!'};
        bool = 0;
        return
    end
    
elseif isempty(classIdx)
    ROIcomposed = falseColorsComet(ROIori, MaskHead, MaskComet, flag_CurrentCometType);
    app.comet_handles.ROIshown = 1;
    app.comet_handles.ROIori = ROIori;
    app.comet_handles.ROIoriFiltered = ROIoriFiltered;
    app.comet_handles.ROIsegm = ROIsegm;
    app.comet_handles.MaskHead = MaskHead;
    app.comet_handles.MaskComet = MaskComet;
    if isempty(cometProp)
        app.comet_handles.ROI_ULCyx_DRCyx = [BB(1,1),BB(2,2),BB(2,1),BB(1,2)];
    else
        app.comet_handles.ROI_ULCyx_DRCyx = [BB2(1,1),BB2(2,2),BB2(2,1),BB2(1,2)];
    end
else
    errorString = {'Multiple class IDs have been found in the selected region.';...
                    'Please contact the developer!'};
    return
end
app.scope.ImageSource = uint8(ROIcomposed);
bool = 1;