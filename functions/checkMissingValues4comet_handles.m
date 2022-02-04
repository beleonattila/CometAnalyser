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

bool = 0;
% Image path
while bool == 0
    if isempty(comet_handles.PathInputFolderOriginal)
        uiwait(helpdlg('Input image folder path is missing. Please set the path...'))
        newPath = uigetdir;
        if ~isempty(newPath)
            if isnumeric(newPath)
                return
            else
                bool = 1;
                comet_handles.PathInputFolderOriginal = newPath;
            end
        end
    else
        bool = 1;
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
    bool = 0;
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
        bool = 0;
        return
    end
end

% Image size and number of images
[w,h,~,n] = size(comet_handles.Imgs_Composed);
comet_handles.ImageSize = [w, h];
comet_handles.NumImages = n;

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
            bool = 0;
            while bool == 0
                if isempty(comet_handles.PathInputFolderOriginal)
                    uiwait(helpdlg('Input image folder path is missing. Please set the path...'))
                    newPath = uigetdir;
                    if ~isempty(newPath)
                        if isnumeric(newPath)
                            return
                        else
                            bool = 1;
                            comet_handles.PathInputFolderOriginal = newPath;
                        end
                    end
                end
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

if ~isempty(comet_handles.Classes)
    classNames = fieldnames(comet_handles.Classes);
    comet_handles.ClassCounter = numel(classNames);
    comet_handles = classVersionControl(comet_handles);
else
    % Set Imgs_Stretched
    if isempty(comet_handles.Imgs_Stretched)
        comet_handles.Imgs_Stretched = oldComposed2NewStretched(comet_handles.Imgs_Composed);
    else
        tempImgs_Stretched = oldComposed2NewStretched(comet_handles.Imgs_Composed);
        comet_handles.Imgs_Stretched(:,:,2:3,:) = tempImgs_Stretched(:,:,2:3,:);
    end
end

comet_handles.Imgs_Ori = comet_handles.Imgs_Stretched(:,:,1,:);
comet_handles.Imgs_Composed = [];

bool = 1;