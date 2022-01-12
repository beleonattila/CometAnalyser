function [bool, comet_handles] = checkMissingValues4comet_handles(comet_handles)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: Jan 11, 2022
% NAME: checkMissingValues4comet_handles (version 1.0)
%
% Check missing values in handle and ask for input.
%
% INPUT:
%   comet_handles                 Handles of the application (app.comet_handles).
%
%
% Copyright © 2022 Filippo Piccinini
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

% Image path
if isempty(comet_handles.PathInputFolderOriginal)
    uiwait(helpdlg('Input image folder path is missing. Please set the path...'))
    newPath = uigetdir;
    if ~isempty(newPath)
        comet_handles.PathInputFolderOriginal = newPath;
    else
        return
    end
end

% Fluorescent or Silver stained
answer = questdlg('Is this project SILVER STAINED or FLUORESCENT?','Project type','Silver Stained','Fluorescent','Silver Stained');
if ~isempty(answer)
    if strcmp(answer,'Silver Stained')
        comet_handles.FluorescenceImages = 0;
    else
        comet_handles.FluorescenceImages = 1;
    end
else
    return
end

% Image extension
if isempty(comet_handles.ImageFormat)
    uiwait(helpdlg('Please set the format of images.'))
    extensionTypes = {'jpg','bmp','png','tif','tiff'};
    answer = listdlg('PromptString','Image format','SelectionMode','single','ListString',extensionTypes);
    if ~isempty(answer)
        comet_handles.ImageFormat = extensionTypes{answer};
    else
        return
    end
end

% Image size and number of images
[w,h,ch,n] = size(comet_handles.Imgs_Composed);
comet_handles.ImageSize = [w, h];
comet_handles.NumImages = n;

% Set Imgs_Stretched
if isempty(comet_handles.Imgs_Stretched)
    comet_handles.Imgs_Stretched = comet_handles.Imgs_Composed(:,:,2,:);
end

% Set DirList

if isempty(comet_handles.dirList)
    dirBool = 1;
    while dirBool
        tempDirList = dir([comet_handles.PathInputFolderOriginal,filesep,'*.',comet_handles.ImageFormat]);
        if ~isempty(tempDirList)
            dirBool = 0;
            comet_handles.dirList = tempDirList;
        else
            uiwait(helpdlg('Input image folder path is missing. Please set the path...'))
            newPath = uigetdir;
            if ~isempty(newPath)
                comet_handles.PathInputFolderOriginal = newPath;
            else
                return
            end
            uiwait(helpdlg('Please set the format of images.'))
            extensionTypes = {'jpg','bmp','png','tif','tiff'};
            answer = listdlg('PromptString','Image format','SelectionMode','single','ListString',extensionTypes);
            if ~isempty(answer)
                comet_handles.ImageFormat = extensionTypes{answer};
            else
                return
            end
        end
    end
end

% Set image names
if isempty(comet_handles.ImgsNames)
    comet_handles.ImgsNames = comet_handles.dirList.name;
end

% Set index of shown image
if isempty(comet_handles.IndImgShown)
    comet_handles.IndImgShown = 1;
end

% Set ClassCounter
if ~isempty(comet_handles.Classes)
    classNames = fieldnames(comet_handles.Class);
    comet_handles.ClassCounter = numel(classNames);
elseif sum(comet_handles.Imgs_Composed(:,:,4,:),'all') > 0
    comet_handles.ClassCounter = 1;
    comet_handles.Classes.Unclassified.Members = [];
    comet_handles.Classes.Unclassified.num_el = 0;
    comet_handles.Classes.Unclassified.ID = 1;
    comet_handles.Imgs_Composed(:,:,4,:) = comet_handles.Imgs_Composed(:,:,4,:)*255;
end

bool = 1;