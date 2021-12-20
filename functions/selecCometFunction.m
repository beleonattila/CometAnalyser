function [iscomplete, errorString] = selecCometFunction(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 20, 2021
% NAME: selecCometFunction (version 1.0)
% 
% Performing the method of comet selection from shown image by drawing a
% poligon or click on a presegmented comet to load into the scope for
% manual segmentation or to perform class operations. (add or remove)
%
% INPUT:
%   app                 Handles of the application.          
%
% OUTPUT:
%   iscomplete          Succes indicator bool
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
app.selectedComet = [];
app.scope.ImageSource = app.CometIcon;
app.comet_handles.ROIshown = 0;
app.comet_handles.ROIori = [];
app.comet_handles.ROIoriFiltered = [];
app.comet_handles.ROIsegm = [];
app.comet_handles.MaskComet = [];
app.comet_handles.MaskHead = [];
app.comet_handles.ROI_ULCyx_DRCyx = [];
app.comet_handles.CurrentCometHead_YrowXcol = [];

[yrowOri, xcolOri, ~, ~] = size(app.comet_handles.Imgs_Stretched(:,:,1,app.comet_handles.IndImgShown));

% Manual selection with freehand selection
try
    
    % New version: multiple-selection
    % New version from: http://stackoverflow.com/questions/23463516/draw-multiple-regions-on-an-image-imfreehand
    clear BWout1
    hFigFree2 = drawfreehand(app.axes1);
    
    % If a right ROI has been selected, this gives the opportunity to move the ROI
    wait( hFigFree2 );
    % Check on the minimum number of pixels of the ROI selected
    if ~isvalid(hFigFree2) || numel(find(createMask(hFigFree2)==1))<=app.comet_handles.ROIminNumPixels
        iscomplete = 0;
        errorString = {'The selected region is too small!'};
        if exist('hFigFree2', 'var'); delete(hFigFree2); end
    else
        PartialMask = createMask( hFigFree2 );
        
        BWout1 = zeros(yrowOri, xcolOri);
        BWout1(PartialMask) = 1;
        
        clear pos
        pos = hFigFree2.Position;
        xHi = round(min([max(pos(:,2)); yrowOri]));
        yHi = round(min([max(pos(:,1)); xcolOri]));
        xLow = round(max([min(pos(:,2)); 1]));
        yLow = round(max([min(pos(:,1)); 1]));
        BB = [xLow, yHi;...
            xHi, yLow];
        
        % Delete line
        if exist('hFigFree2', 'var'); delete(hFigFree2); end
        [bool, errorString] = ROI_processing(app, BB, BWout1, []);
        
        if bool == 0
            if isempty(errorString)
                errorString = {'No comet has been detected.'};
            end
            iscomplete = 0;
            return
        end
        iscomplete = 1;
    end
catch ME
    iscomplete = 0;
    errorString = {'Wrong segmentation.';'';'';'Error description:';'';ME.message};
end