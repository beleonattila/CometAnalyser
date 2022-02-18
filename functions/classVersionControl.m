function comet_handles = classVersionControl(comet_handles)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: February 4, 2021
% Updated: February 18, 2022
% NAME: classVersionControl (version 1.0)
%
% Converting old class structure to the latest version.
%
% INPUT:
%   comet_handles       Original comet_handles
%
% OUTPUT:
%   comet_handles       Corrected comet_handles
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

classNames = fieldnames(comet_handles.Classes);
ImgsNames = comet_handles.ImgsNames;
comet_handles.Imgs_Stretched(:,:,2:3,:) = 0;
wb = waitbar(0,sprintf('Converting class structure. Please wait...\n %d / %d class(es)',0,numel(classNames)));
for i = 1:numel(classNames)
    n = size(comet_handles.Classes.(classNames{i}).Members,2);
    for j = n:-1:1
        if ishandle(wb)
            waitbar((n-j)/n,wb,sprintf('Converting class structure. Please wait...\n %d / %d class(es)',i,numel(classNames)));
        end
        currentImName = comet_handles.Classes.(classNames{i}).Members(j).ImName;
        imIdx = strcmp(ImgsNames,currentImName);
        IDsOnThisImage = unique(comet_handles.Imgs_Stretched(:,:,2,imIdx));
        freeIDs = setdiff(1:255,IDsOnThisImage);
        cometID = min(freeIDs);
        BB = comet_handles.Classes.(classNames{i}).Members(j).thumbnailCoor;
        cometMaskLayer = comet_handles.Imgs_Composed(:,:,4,imIdx);
        x = round(mean(BB(:,1)));
        y = round(mean(BB(:,2)));
        selectedCometMask = bwselect(logical(cometMaskLayer),y,x,4);
        linearCometIdx = find(selectedCometMask);
        selectedCometMask = uint8(selectedCometMask) * cometID;
        
        headMaskLayer = comet_handles.Imgs_Composed(:,:,3,imIdx) == 255;
        linearHeadIdx = headMaskLayer(linearCometIdx) == 1;
        selectedHeadMask = zeros(comet_handles.ImageSize);
        selectedHeadMask(linearCometIdx(linearHeadIdx)) = cometID;
        if any(selectedCometMask,'all') || any(selectedHeadMask,'all')
            comet_handles.Imgs_Stretched(:,:,2,imIdx) = comet_handles.Imgs_Stretched(:,:,2,imIdx) + uint8(selectedCometMask);
            comet_handles.Imgs_Stretched(:,:,3,imIdx) = comet_handles.Imgs_Stretched(:,:,3,imIdx) + uint8(selectedHeadMask);
            comet_handles.Classes.(classNames{i}).Members(j).cometID = cometID;
            comet_handles.Classes.(classNames{i}).Members(j).ImID = [];
            comet_handles.Classes.(classNames{i}).Members(j).thumbnailCoor = [];
            comet_handles.Classes.(classNames{i}).Members(j).mask = [];
        else
            comet_handles.Classes.(classNames{i}).Members(j) = [];
        end
    end
end
if ishandle(wb), close(wb), end