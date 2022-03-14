function [bool, warnString] = removeComet(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% Updated: March 14, 2022
% NAME: removeComet (version 1.0)
%
% Removing the selected, presegmented and classified comet from its class.
%
% INPUT:
%   app                 Handles of the application.
%
% OUTPUT:
%   bool                Succes indicator bool
%   warnString          Error message if something goes wrong
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

warnString = [];
bool = 0;

if ~strcmp(app.selectedComet.className,'Prediction')    
    classNames = fieldnames(app.comet_handles.Classes);
    classIdx = [];
    % Find the index of the selected comet in the class structure
    for i = 1:numel(classNames)
        if ~isempty(app.comet_handles.Classes.(classNames{i}).Members)
            imFileter = strcmp({app.comet_handles.Classes.(classNames{i}).Members.ImName},app.comet_handles.ImgsNames{app.comet_handles.IndImgShown});
            cometIDFilter = [app.comet_handles.Classes.(classNames{i}).Members.cometID] == app.selectedComet.param.cometID;
            if any(imFileter & cometIDFilter)
                idToShow = find(imFileter & cometIDFilter);
                classIdx = i;
                break
            end
        end
    end
    if isempty(classIdx)
        warnString = {'Corrupted class structure!'};
        return
    end
    % Delete the selected comet from the class
    app.comet_handles.Classes.(classNames{i}).Members(idToShow)= [];
end

cometID = app.selectedComet.param.cometID;
ImID = strcmp(app.selectedComet.param.ImName,app.comet_handles.ImgsNames);
CometMaskLayer = app.comet_handles.Imgs_Stretched(:, :, 2, ImID);
HeadMaskLayer = app.comet_handles.Imgs_Stretched(:, :, 3, ImID);
if cometID < 255
    CometMaskLayer(CometMaskLayer == cometID) = 0;
    HeadMaskLayer(HeadMaskLayer == cometID) = 0;
else
    coor = app.selectedComet.param.coor;
    BW = bwselect(app.comet_handles.Imgs_Stretched(:,:,2,app.comet_handles.IndImgShown),coor(1),coor(2));
    CometMaskLayer(BW) = 0;
    HeadMaskLayer(BW) = 0;
end
app.comet_handles.Imgs_Stretched(:, :, 2, ImID) = CometMaskLayer;
app.comet_handles.Imgs_Stretched(:, :, 3, ImID) = HeadMaskLayer;
app.selectedComet = [];

if ~isempty(app.imDatatipText)
    delete(app.imDatatipText)
    app.imDatatipText = [];
end
app.comet_handles.uniqueIdentifier = now;
bool = 1;