function [iscomplete, errorString] = clickOnCometSelection(app, coor)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 22, 2021
% NAME: clickOnCometSelection (version 1.0)
%
% Select an already segmented comet by simply click on it
%
% INPUT:
%   app                 Handles of the application
%   coor                Coordinates of cursor
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

iscomplete = 0;
errorString = [];
classNames = fieldnames(app.comet_handles.Classes);
classIdx = [];
cometIdxTail = app.comet_handles.Imgs_Stretched(coor(2),coor(1),2,app.comet_handles.IndImgShown);
if cometIdxTail < 255
    for i = 1:numel(classNames)
        if ~isempty(app.comet_handles.Classes.(classNames{i}).Members)
            imFileter = strcmp({app.comet_handles.Classes.(classNames{i}).Members.ImName},app.comet_handles.ImgsNames{app.comet_handles.IndImgShown});
            cometIDFilter = [app.comet_handles.Classes.(classNames{i}).Members.cometID] == cometIdxTail;
            if any(imFileter & cometIDFilter)
                idToShow = find(imFileter & cometIDFilter);
                classIdx = i;
                break
            end
        end
    end
    
    if ~isempty(classIdx)
        IndImgShown = app.comet_handles.IndImgShown;
        
        [xCoor,yCoor] = find(app.comet_handles.Imgs_Stretched(:,:,2,IndImgShown) == cometIdxTail);
        xMin = min(xCoor);
        xMax = max(xCoor);
        yMin = min(yCoor);
        yMax = max(yCoor);
        
        BB = [xMin, yMax;...
            xMax, yMin];
        cometProp = app.comet_handles.Classes.(classNames{i}).Members(idToShow);
        app.selectedComet.coor = coor;
        [bool, errorString] = ROI_processing(app, BB, [], cometProp);
        if bool == 0
            return
        end
        app.selectedComet.className = classNames{classIdx};
        app.selectedComet.param = cometProp;
    else
        errorString = {'There is no matching instance in class structure';
                       'Please contact the developer!'};
          return
    end
else % Predicted mask (green and magenta)
    BW2 = bwselect(app.comet_handles.Imgs_Stretched(:,:,2,app.comet_handles.IndImgShown),coor(1),coor(2));
    [maskRow, maskCol] = find(BW2==1);
    BB = [min(maskRow), max(maskCol);...
        max(maskRow), min(maskCol)];
    
%     app.selectedComet.param.ImID = app.comet_handles.IndImgShown;
    app.selectedComet.param.cometID = 255;
    app.selectedComet.className = 'Prediction';
    app.selectedComet.coor = coor;
    [bool, errorString] = ROI_processing(app, BB, [], app.selectedComet.param);
    if bool == 0
        return
    end
end
iscomplete = 1;