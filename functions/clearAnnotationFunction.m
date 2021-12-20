function clearAnnotationFunction(app)
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

imIdx = app.comet_handles.IndImgShown;
ImgNames = app.comet_handles.ImgsNames{imIdx};
classIDsOnThisIm = setdiff(unique(app.comet_handles.Imgs_Composed(:,:,4,imIdx)),[0, 255]);

if any(classIDsOnThisIm)
    classStruct = app.comet_handles.Classes;
    classNames = fieldnames(classStruct);
    classID = zeros(numel(classNames),1);
    
    
    for i = 1:numel(classNames)
        classID(i) = classStruct.(classNames{i}).ID;
    end
    
    for i = 1:numel(classIDsOnThisIm)
        imNameIDX = strcmp({classStruct.(classNames{classID(i)}).Members.ImName},ImgNames);
        classStruct.(classNames{classID(i)}).Members(imNameIDX) = [];
        classStruct.(classNames{classID(i)}).num_el = classStruct.(classNames{classID(i)}).num_el - sum(imNameIDX);
    end
    app.comet_handles.Classes = classStruct;
end
app.comet_handles.Imgs_Composed(:,:,1,imIdx) = app.comet_handles.Imgs_Stretched(:,:,1,imIdx);
app.comet_handles.Imgs_Composed(:,:,2,imIdx) = app.comet_handles.Imgs_Stretched(:,:,1,imIdx);
app.comet_handles.Imgs_Composed(:,:,3,imIdx) = app.comet_handles.Imgs_Stretched(:,:,1,imIdx);
app.comet_handles.Imgs_Composed(:,:,4,imIdx) = app.comet_handles.Imgs_Composed(:,:,4,imIdx)*0;
