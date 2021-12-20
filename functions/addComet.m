function [bool, warnString] = addComet(app,className)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 22, 2021
% NAME: addComet (version 1.0)
%
% Manually adding the selected comet to a class.
%
% INPUT:
%   app                 Handles of the application
%   classID             Target class to add new element
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

warnString = [];
bool = 0;
if strcmp(app.pop_class.Value,'~No Class~')
    warnString = {'Create a class first!'};
    return
end

if ~isempty(app.selectedComet) % If the comet is presegmented
%     BB = app.selectedComet.param.thumbnailCoor;
%     coor = [round((BB(2,2)+BB(1,2))/2), round((BB(1,1)+BB(2,1))/2)];
%     classIdx = app.comet_handles.Imgs_Composed(coor(2),coor(1),4,app.comet_handles.IndImgShown);
%     if classIdx < 255 % If the comet is manually segmented (Red & Blue)
        [bool2, warnString] = removeComet(app);
        if bool2 == 0
            warnString = {'Failed to remove comet from previous class.'};
            return
        end
%     end
end

MaskHead = app.comet_handles.MaskHead;
MaskComet = app.comet_handles.MaskComet;
% flag_CurrentCometType = app.comet_handles.flag_CurrentCometType;
ROI_ULCyx_DRCyx = app.comet_handles.ROI_ULCyx_DRCyx;
ULC_Yrow_roi = ROI_ULCyx_DRCyx(1,1); ULC_Xcol_roi = ROI_ULCyx_DRCyx(1,2); DRC_Yrow_roi = ROI_ULCyx_DRCyx(1,3); DRC_Xcol_roi = ROI_ULCyx_DRCyx(1,4);
IndImgShown = app.comet_handles.IndImgShown;
Imgs_Composed = app.comet_handles.Imgs_Composed(:,:,:,IndImgShown);
% ROIori = app.comet_handles.ROIori;

% To delete external pixels in case of perfect fit.
flag_CometFitFreehand = app.comet_handles.flag_CometFitFreehand;
ROIsegm = app.comet_handles.ROIsegm;
if flag_CometFitFreehand == 1
    if ~isempty(MaskHead)
        MaskHead(ROIsegm==0)=0;
    end
    if ~isempty(MaskComet)
        MaskComet(ROIsegm==0)=0;
    end
end
classID = app.comet_handles.Classes.(className).ID;
ROIcomposed = app.scope.ImageSource;

[rowI, colI, ~] = size(Imgs_Composed);
ImgComposedCh1 = Imgs_Composed(:, :, 1);
ImgComposedCh2 = Imgs_Composed(:, :, 2);
ImgComposedCh3 = Imgs_Composed(:, :, 3);
ImgComposedCh4 = Imgs_Composed(:, :, 4);
ImgMaskInd = zeros(rowI, colI);
ImgROIcomposedCh1 = zeros(rowI, colI);
ImgROIcomposedCh2 = zeros(rowI, colI);
ImgROIcomposedCh3 = zeros(rowI, colI);
ImgROIcomposedCh1(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = ROIcomposed(:,:,1);
ImgROIcomposedCh2(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = ROIcomposed(:,:,2);
ImgROIcomposedCh3(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = ROIcomposed(:,:,3);
ImgMaskInd(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = MaskComet;
Inds = find(ImgMaskInd==1);

if isempty(Inds)
    warnString = {'No comet has been selected.'};
    return
end

ImgComposedCh1(Inds) = ImgROIcomposedCh1(Inds);
ImgComposedCh2(Inds) = ImgROIcomposedCh2(Inds);
ImgComposedCh3(Inds) = ImgROIcomposedCh3(Inds);
ImgComposedCh4(Inds) = classID;
Imgs_Composed(:, :, 1) = ImgComposedCh1;
Imgs_Composed(:, :, 2) = ImgComposedCh2;
Imgs_Composed(:, :, 3) = ImgComposedCh3;
Imgs_Composed(:, :, 4) = ImgComposedCh4;


[maskRow, maskCol] = find(ImgMaskInd==1);

thumbnailCoor = [min(maskRow), max(maskCol);...
    max(maskRow), min(maskCol)];

if app.comet_handles.Classes.(className).num_el < 1
    upcomingIdx = 1;
else
    numOfElements = app.comet_handles.Classes.(className).num_el;
    upcomingIdx = numOfElements + 1;
end
app.comet_handles.Classes.(className).Members(upcomingIdx).ImName = app.comet_handles.ImgsNames{IndImgShown};
app.comet_handles.Classes.(className).Members(upcomingIdx).ImID = IndImgShown;
app.comet_handles.Classes.(className).Members(upcomingIdx).thumbnailCoor = thumbnailCoor;
app.comet_handles.Classes.(className).Members(upcomingIdx).mask = ImgMaskInd(thumbnailCoor(1,1):thumbnailCoor(2,1),thumbnailCoor(2,2):thumbnailCoor(1,2));
app.comet_handles.Classes.(className).num_el = upcomingIdx;
if ~isempty(app.imDatatipText)
    delete(app.imDatatipText)
    app.imDatatipText = [];
end
app.comet_handles.Imgs_Composed(:,:,:,IndImgShown) = Imgs_Composed;
app.comet_handles.FlagNewComets = app.comet_handles.FlagNewComets + 1;
bool = 1;