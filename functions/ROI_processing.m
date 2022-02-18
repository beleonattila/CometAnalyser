function [bool, errorString] = ROI_processing(app, BB, BWout1, cometProp)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 20, 2021
% Updated: February 18, 2022
% NAME: ROI_processing (version 1.0)
%
% Calculating the required data for app.comet_handles.Roi and .masks
% properties, updating the scope image with the result.
%
% INPUT:
%   app                 Handles of the application.
% 	BB                  Bounding box of selected comet to show in scope
%   BWout1              Binary mask image of selected comet
%   cometProp           Struct containing the ID of the comet and the image
%                       name
%
% OUTPUT:
%   bool                Succes indicator bool
%   errorString         Error message if something goes wrong
%

% Copyright © 2022 Filippo Piccinini and Attila Beleon.
% Contacts: filippo.piccinini85@gmail.com and beleonattila@gmail.com
% All rights reserved.
%
% CometAnalyser and all related material is licensed
% under the: 3-clause BSD License.
%
% This software and all related material is provided by the copyright
% holders and contributors "as is" and any express or implied warranties,
% including, but not limited to, the implied warranties of merchantability
% and fitness for a particular purpose are disclaimed. In no event shall
% <copyright holder> be liable for any direct, indirect, incidental,
% special, exemplary, or consequential damages (including, but not limited
% to, procurement of substitute goods or services; loss of use, data, or
% profits; or business interruption) however caused and on any theory of
% liability, whether in contract, strict liability, or tort (including
% negligence or otherwise) arising in any way out of the use of this
% software, even if advised of the possibility of such damage.

errorString = [];
bool = 0;
IndImgShown = app.comet_handles.IndImgShown;
ImgShownStretched = app.comet_handles.Imgs_Stretched(:,:,1,IndImgShown);
ImgShownOri = app.comet_handles.Imgs_Ori(:,:,1,IndImgShown);

ROIStretched = ImgShownStretched(BB(1,1):BB(2,1),BB(2,2):BB(1,2));
ROIori = ImgShownOri(BB(1,1):BB(2,1),BB(2,2):BB(1,2));
if all(ROIStretched(:)==0) || all(ROIStretched(:)==255)
    bool = 0;
    errorString = {'No comet was found in the region.'};
    return
end

ImgShownFiltered = medfilt2(ImgShownOri, [5, 5], 'symmetric');
h = fspecial('average', 3);
ImgShownFiltered = imfilter(ImgShownFiltered, h, 'symmetric');
ROIoriFiltered = ImgShownFiltered(BB(1,1):BB(2,1),BB(2,2):BB(1,2));
flag_CurrentCometType = app.comet_handles.flag_CurrentCometType;
flag_CometFitFreehand = app.comet_handles.flag_CometFitFreehand;
MaskHead = [];

% Segment comet
if isempty(cometProp) % in the case of drawn segmentation
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
    % ID is already there or not.
    cometLayer = app.comet_handles.Imgs_Stretched(BB(1,1):BB(2,1),BB(2,2):BB(1,2), 2, IndImgShown);
    cometIdxTail = unique(cometLayer(logical(MaskComet)));
    cometIdxTail = cometIdxTail(cometIdxTail>0);
    
else % Comet selected by clicking on it has been segmented and classified already.
    if cometProp.cometID < 255
        % Calclating an enlarged bounding box
        radiusScaler = 30;
    else
        radiusScaler = 10;
    end
    
    xRadius = floor(log(BB(2,1) - BB(1,1))*radiusScaler);
    yRadius = floor(log(BB(1,2) - BB(2,2))*radiusScaler);
    w = app.comet_handles.ImageSize(1);
    h = app.comet_handles.ImageSize(2);
    xL = max(1,BB(1,1)-xRadius);
    xH = min(w,BB(2,1)+xRadius);
    yL = max(1,BB(2,2)-yRadius);
    yH = min(h,BB(1,2)+yRadius);
    
    BB2 = [xL, yH;... % This is the enlarged Bounding box
        xH, yL];
    ROIStretched = ImgShownStretched(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2));
    ROIoriFiltered = ImgShownOri(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2));
    neigbourhoodMask = app.comet_handles.Imgs_Stretched(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2),2,IndImgShown);
    if cometProp.cometID < 255
        MaskComet = neigbourhoodMask;
        MaskComet(MaskComet~=cometProp.cometID) = 0;
        MaskHead = app.comet_handles.Imgs_Stretched(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2),3,IndImgShown);
        MaskHead(MaskHead~=cometProp.cometID) = 0;
        MaskComet = logical(MaskComet);
        MaskHead = logical(MaskHead);
    else
        BWim = logical(app.comet_handles.Imgs_Stretched(:,:,2,IndImgShown));
        coor = app.selectedComet.param.coor;
        isolatedCometMaskLayer = bwselect(BWim,coor(1),coor(2),4);
        MaskComet = isolatedCometMaskLayer(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2));
        MaskHead = logical(app.comet_handles.Imgs_Stretched(BB2(1,1):BB2(2,1),BB2(2,2):BB2(1,2),3,IndImgShown));
        MaskHead(~MaskComet) = 0;
    end
    neigbourhoodMask(MaskComet) = 0;
    SE = strel('ball',3,3);
    neigbourhoodMask = imdilate(neigbourhoodMask,SE);
    SE2 = strel('rectangle',[xRadius, yRadius]);
    tempROIsegm = imdilate(MaskComet, SE2);
    ROIsegm = uint8(tempROIsegm .* imcomplement(logical(neigbourhoodMask)));
    cometIdxTail = [];
end

if length(cometIdxTail) == 1 % in case there are other segmented comets in the region
    if cometIdxTail < 255
        classNames = fieldnames(app.comet_handles.Classes);
        for i = 1:numel(classNames)
            imFileter = strcmp({app.comet_handles.Classes.(classNames{i}).Members.ImName},app.comet_handles.ImgsNames{IndImgShown});
            cometIDFilter = [app.comet_handles.Classes.(classNames{i}).Members.cometID] == cometIdxTail;
            if any(imFileter & cometIDFilter)
                idToShow = find(imFileter & cometIDFilter);
                break
            end
        end
        
        if ~isempty(idToShow)
            app.selectedComet.className = classNames{i};
            app.selectedComet.param = app.comet_handles.Classes.(classNames{i}).Members(idToShow);
            [xCoor,yCoor] = find(app.comet_handles.Imgs_Stretched(:,:,2,IndImgShown) == cometIdxTail);
            xMin = max([round(min(xCoor) - (max(xCoor) - min(xCoor))/2),1]);
            xMax = min([round(max(xCoor) + (max(xCoor) - min(xCoor))/2),app.comet_handles.ImageSize(1)]);
            yMin = max([round(min(yCoor) - (max(yCoor) - min(yCoor))/2),1]);
            yMax = min([round(max(yCoor) + (max(yCoor) - min(yCoor))/2),app.comet_handles.ImageSize(2)]);
            ROIcomposed = uint8(falseColorsComet(app.comet_handles.Imgs_Stretched(xMin:xMax,yMin:yMax,1,IndImgShown),...
                app.comet_handles.Imgs_Stretched(xMin:xMax,yMin:yMax,3,IndImgShown),...
                app.comet_handles.Imgs_Stretched(xMin:xMax,yMin:yMax,2,IndImgShown),...
                flag_CurrentCometType));
        else
            errorString = {'The selected region might touch a classified object. Please select another region!'};
            bool = 0;
            return
        end
    else
        ROIcomposed = uint8(falseColorsComet(app.comet_handles.Imgs_Stretched(BB(1,1):BB(2,1),BB(2,2):BB(1,2),1,IndImgShown),...
                                             app.comet_handles.Imgs_Stretched(BB(1,1):BB(2,1),BB(2,2):BB(1,2),3,IndImgShown),...
                                             app.comet_handles.Imgs_Stretched(BB(1,1):BB(2,1),BB(2,2):BB(1,2),2,IndImgShown),...
                                             flag_CurrentCometType));
        app.selectedComet.className = 'Prediction';
        app.selectedComet.param.cometID = 255;
        app.selectedComet.param.ImName = app.comet_handles.ImgsNames(app.comet_handles.IndImgShown);
        separatedSelectedMask = uint8(BWout1) .* app.comet_handles.Imgs_Stretched(:,:,2,IndImgShown);
        centroid = calcLargestInnerTriangleCentorid(logical(separatedSelectedMask));
        app.selectedComet.param.coor = [centroid(2), centroid(1)];
    end
    
    
elseif isempty(cometIdxTail)
    ROIcomposed = falseColorsComet(ROIStretched, MaskHead, MaskComet, flag_CurrentCometType);
    app.comet_handles.ROIshown = 1;
    app.comet_handles.ROIori = ROIStretched;
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
    errorString = {'Multiple comet IDs have been found in the selected region.';...
        'Please contact the developer!'};
    return
end
app.scope.ImageSource = uint8(ROIcomposed);
bool = 1;