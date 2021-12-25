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

iscomplete = 0;
errorString = [];
classIdx = app.comet_handles.Imgs_Composed(coor(2),coor(1),4,app.comet_handles.IndImgShown);
if classIdx == 0
    [tempX, tempY] = find(app.comet_handles.Imgs_Composed(:,:,4,app.comet_handles.IndImgShown));
    [~, idx] = min(sqrt((tempX-coor(2)).^2 + (tempY - coor(1)).^2));
    classIdx = app.comet_handles.Imgs_Composed(tempX(idx(1)),tempY(idx(1)),4,app.comet_handles.IndImgShown);
end
IndImgShown = app.comet_handles.IndImgShown;
if classIdx < 255
    classNames = fieldnames(app.comet_handles.Classes);
    membersOnThisImage = app.comet_handles.Classes.(classNames{classIdx}).Members([app.comet_handles.Classes.(classNames{classIdx}).Members.ImID] == IndImgShown);
    idToShow = [];
    for i = 1:size(membersOnThisImage,2)
        currentThumbcoor = membersOnThisImage(i).thumbnailCoor;
        if currentThumbcoor(1, 1) < coor(2) && currentThumbcoor(2, 1) > coor(2) &&...
                currentThumbcoor(2, 2) < coor(1) && currentThumbcoor(1, 2) > coor(1)
            if isempty(idToShow)
                idToShow = i;
            else
                errorString = {'Selected coordinates have been found stored as coordinates of multipe class members!';...
                    '  Please contact the developer!'};
                return
            end
        end
    end
    if ~isempty(idToShow)
        coorToShow = membersOnThisImage(idToShow).thumbnailCoor;
        BB = coorToShow;
        cometProp = membersOnThisImage(idToShow);
        [bool, errorString] = ROI_processing(app, BB, [], cometProp);
        if bool == 0
            return
        end
        app.selectedComet.className = classNames{classIdx};
        app.selectedComet.param = membersOnThisImage(idToShow);
    end
else
    BW2 = bwselect(app.comet_handles.Imgs_Composed(:,:,4,app.comet_handles.IndImgShown),coor(1),coor(2));
    [maskRow, maskCol] = find(BW2==1);
    BB = [min(maskRow), max(maskCol);...
        max(maskRow), min(maskCol)];
    
    app.selectedComet.param.mask = BW2(BB(1,1):BB(2,1),BB(2,2):BB(1,2));
    app.selectedComet.param.thumbnailCoor = BB;
    app.selectedComet.param.ImID = IndImgShown;
    app.selectedComet.className = 'Prediction';
    [bool, errorString] = ROI_processing(app, BB, [], app.selectedComet.param);
    if bool == 0
        return
    end
end
iscomplete = 1;