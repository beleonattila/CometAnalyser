function [bool, errorString] = addComet(app,className)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 22, 2021
% Updated: March 14, 2022
% NAME: addComet (version 1.0)
%
% Adding the selected comet to a class.
%
% INPUT:
%   app                 Handles of the application
%   className           String, name of the selected class
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
if strcmp(app.pop_class.Value,'~No Class~')
    errorString = {'Create a class first!'};
    return
end

if ~isempty(app.selectedComet) % If the comet is presegmented
    [bool2, errorString] = removeComet(app);
    if bool2 == 0
        errorString = {'Failed to remove comet from previous class.'};
        return
    end
end

MaskHead = app.comet_handles.MaskHead;
MaskComet = app.comet_handles.MaskComet;
ROI_ULCyx_DRCyx = app.comet_handles.ROI_ULCyx_DRCyx;
ULC_Yrow_roi = ROI_ULCyx_DRCyx(1,1); ULC_Xcol_roi = ROI_ULCyx_DRCyx(1,2); DRC_Yrow_roi = ROI_ULCyx_DRCyx(1,3); DRC_Xcol_roi = ROI_ULCyx_DRCyx(1,4);
IndImgShown = app.comet_handles.IndImgShown;
Imgs_Stretched = app.comet_handles.Imgs_Stretched(:,:,:,IndImgShown);

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

[rowI, colI, ~] = size(Imgs_Stretched);
cometMaskLayer = Imgs_Stretched(:,:,2);
headMaskLayer = Imgs_Stretched(:,:,3);
ImgMaskInd = false(rowI, colI);
if ~isempty(MaskHead)
    ImgMaskInd(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = MaskHead;
    Inds_head = find(ImgMaskInd);
end
ImgMaskInd(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = ImgMaskInd(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) + logical(MaskComet);
Inds_comet = find(ImgMaskInd);

if isempty(Inds_comet)
    errorString = {'No comet has been selected.'};
    return
end

cometID = min(setdiff(1:255,cometMaskLayer),[],'all');


if cometID == 255
    errorString = {'You reached the limit of maximum number of objects per image.'};
    return
end

cometMaskLayer(Inds_comet) = cometID;
Imgs_Stretched(:, :, 2) = cometMaskLayer;
if ~isempty(MaskHead)
    headMaskLayer(Inds_head) = cometID;
    Imgs_Stretched(:, :, 3) = headMaskLayer;
end

upcomingIdx = size(app.comet_handles.Classes.(className).Members,2) + 1;
app.comet_handles.Classes.(className).Members(upcomingIdx).ImName = app.comet_handles.ImgsNames{IndImgShown};
app.comet_handles.Classes.(className).Members(upcomingIdx).cometID = cometID;
if ~isempty(app.imDatatipText)
    delete(app.imDatatipText)
    app.imDatatipText = [];
end
app.comet_handles.Imgs_Stretched(:,:,:,IndImgShown) = Imgs_Stretched;
app.comet_handles.FlagNewComets = app.comet_handles.FlagNewComets + 1;
app.comet_handles.uniqueIdentifier = now;
bool = 1;