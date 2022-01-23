function [bool, warnString] = removeComet(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% NAME: removeComet (version 1.0)
%
% Removing the selected, presegmented and classified comet from its class.
%
% INPUT:
%   app                 Handles of the application.
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

coor = app.selectedComet.param.thumbnailCoor;
mask = app.selectedComet.param.mask;
ImID = app.selectedComet.param.ImID;
Imgs_Stretched = app.comet_handles.Imgs_Stretched(:, :, 1, ImID);
Imgs_Composed1 = app.comet_handles.Imgs_Composed(:,:,1,ImID);
Imgs_Composed2 = app.comet_handles.Imgs_Composed(:,:,2,ImID);
Imgs_Composed3 = app.comet_handles.Imgs_Composed(:,:,3,ImID);
Imgs_Composed4 = app.comet_handles.Imgs_Composed(:,:,4,ImID);
[h,w] = size(Imgs_Composed1);
blankIm = zeros(h,w);
blankIm(coor(1,1):coor(2,1), coor(2,2):coor(1,2)) = mask;
Idx = find(blankIm);
Imgs_Composed1(Idx) = Imgs_Stretched(Idx);
Imgs_Composed2(Idx) = Imgs_Stretched(Idx);
Imgs_Composed3(Idx) = Imgs_Stretched(Idx);
Imgs_Composed4(Idx) = 0;

Imgs_Composed = cat(3,Imgs_Composed1,Imgs_Composed2,Imgs_Composed3,Imgs_Composed4);

if ~strcmp(app.selectedComet.className,'Prediction')
    numOfMembers = app.comet_handles.Classes.(app.selectedComet.className).num_el;
    if numOfMembers <= 1
        app.comet_handles.Classes.(app.selectedComet.className).Members = [];
        app.comet_handles.Classes.(app.selectedComet.className).num_el = 0;
    else
        maskCenterPoint = round([(coor(2, 1) + coor(1, 1))/2, (coor(2, 2) + coor(1, 2))/2]);
        memberIdx = 0;
        for z = 1:numOfMembers
            memberCoor = app.comet_handles.Classes.(app.selectedComet.className).Members(z).thumbnailCoor;
            if maskCenterPoint(1) > memberCoor(1, 1) && maskCenterPoint(1) < memberCoor(2, 1) && ...
                    maskCenterPoint(2) > memberCoor(2, 2) && maskCenterPoint(2) < memberCoor(1, 2)
                memberIdx = z;
                break
            end
        end
        if memberIdx == 0
            warnString = {'Corrupted class structure!'};
            return
        end
        app.comet_handles.Classes.(app.selectedComet.className).Members(memberIdx)= [];
        app.comet_handles.Classes.(app.selectedComet.className).num_el = numOfMembers - 1;
    end
end
app.selectedComet = [];
app.comet_handles.Imgs_Composed(:,:,:,ImID) = Imgs_Composed;
if ~isempty(app.imDatatipText)
    delete(app.imDatatipText)
    app.imDatatipText = [];
end
app.axes1.Children.CData = uint8(Imgs_Composed(:,:,1:3));
bool = 1;