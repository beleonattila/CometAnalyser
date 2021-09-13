function [bool, message] = createUnclassifiedClassForGreens(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: July 14, 2021
% NAME: createUnclassifiedClassForGreens (version 1.0)
%
% Iterate through images and put all the predicted green&pink comets into a
% class named "Unclassified".
%
% INPUT:
%   app                 Handles of the application.
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

bool = 0;
message = 'Process failed.';

currentImShown = app.comet_handles.IndImgShown;
wb = waitbar(0,'Adding segmented comets to "Unclassified" class. Please wait...');
for i = 1:app.comet_handles.NumImages
    app.comet_handles.IndImgShown = i;
    set(app.text_Num,'Text', ['Image: ' num2str(i) '/' num2str(app.comet_handles.NumImages)]);
    set(app.text_Name,'Text', ['Image: ' char(app.comet_handles.ImgsNames{i})]);
    waitbar(0,wb,sprintf('Adding segmented comets to "Unclassified" class. Please wait...\n%d / %d',i,app.comet_handles.NumImages))
    tempIm = app.comet_handles.Imgs_Composed(:,:,4,i);
    BW2 = tempIm == 255;
    L = bwlabel(BW2);
    numOfObj = max(L,[],'all');
    for j = 1:numOfObj
        waitbar(j/numOfObj,wb,sprintf('Adding segmented comets to "Unclassified" class. Please wait...\n%d / %d',i,app.comet_handles.NumImages))
        [xend, yend] = find(bwmorph(L == j,'skel',3));
        coor = [yend(1), xend(1)];
        [iscomplete, errorString] = clickOnCometSelection(app, coor);
        if iscomplete == 1
            [bool, warnString] = addComet(app);
            if bool == 0
                appTextDlg(app, warnString, 'Message', 'error')
                continue
            end
        else
            appTextDlg(app, errorString, 'Corrupted Class structure or segmentation.', 'error')
            app.selectedComet = [];
            app.scope.ImageSource = app.CometIcon;
            app.comet_handles.ROIshown = 0;
            app.comet_handles.ROIori = [];
            app.comet_handles.ROIoriFiltered = [];
            app.comet_handles.ROIsegm = [];
            app.comet_handles.MaskComet = [];
            app.comet_handles.MaskHead = [];
            app.comet_handles.ROI_ULCyx_DRCyx = [];
        end
    end
end
app.comet_handles.IndImgShown = currentImShown;
app.axes1.Children.CData = uint8(app.comet_handles.Imgs_Composed(:,:,1:3,app.comet_handles.IndImgShown));
bool = 1;