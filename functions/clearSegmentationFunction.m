function clearSegmentationFunction(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% NAME: predictImageSegmentation (version 1.0)
%
% Performing automatic segmentation by the selected pretrained network.
%
% INPUT:
%   app                 Handles of the application.
%
% OUTPUT:
%   This function modifies the app.comet_handles.Imgs_Composed by removing
%   green and pink colour from channel 1, 2 and 3
%   Remove class label ID from Channel 4
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

for i = 1:app.comet_handles.NumImages
    if any(app.comet_handles.Imgs_Composed(:,:,4,i) == 255,'all')
        tempStretched = app.comet_handles.Imgs_Stretched(:,:,1,i);
        composed_ch1 = app.comet_handles.Imgs_Composed(:,:,1,i);
        composed_ch2 = app.comet_handles.Imgs_Composed(:,:,2,i);
        composed_ch3 = app.comet_handles.Imgs_Composed(:,:,3,i);
        composed_ch4 = app.comet_handles.Imgs_Composed(:,:,4,i);
        idx = composed_ch4 == 255;
        
        composed_ch1(idx) = tempStretched(idx);
        composed_ch2(idx) = tempStretched(idx);
        composed_ch3(idx) = tempStretched(idx);
        composed_ch4(idx) = tempStretched(idx);
        
        app.comet_handles.Imgs_Composed(:,:,1,i) = composed_ch1;
        app.comet_handles.Imgs_Composed(:,:,2,i) = composed_ch2;
        app.comet_handles.Imgs_Composed(:,:,3,i) = composed_ch3;
        app.comet_handles.Imgs_Composed(:,:,4,i) = composed_ch4;
    end
end