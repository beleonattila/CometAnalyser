function editFreehand(hf, he)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 14, 2021
% Updated: February 18, 2022
% NAME: augmentImageAndLabel (version 1.0)
%
% Augment images and pixel label images using random reflection,
% translation, rotation, resize and noise.
%
% INPUT:
% 	data                Original data for segmentation
%   xTrans              Transition value for X direction
%   yTrans              Transition value for Y direction
%   rotVector           Rotation angle
%   scaleVector         Vector with max and min values of scaling values
%
%
% OUTPUT:
%   data                Augmented data
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

% Create a mask for the target freehand.
tmask = hf.createMask();
[m, n,~] = size(tmask);
% Include the boundary pixel locations
boundaryInd = sub2ind([m,n], hf.Position(:,2), hf.Position(:,1));
tmask(boundaryInd) = true;

% Create a mask from the editor ROI
emask = he.createMask();
boundaryInd = sub2ind([m,n], he.Position(:,2), he.Position(:,1));
emask(boundaryInd) = true;

% Check if center of the editor ROI is inside the target freehand. If you
% use a different editor ROI, ensure to update center computation.
center = he.Center; %
isAdd = hf.inROI(center(1), center(2));
if isAdd
    % Add the editor mask to the freehand mask
    newMask = tmask|emask;
else
    % Delete out the part of the freehand which intersects the editor
    newMask = tmask&~emask;
end

% Update the freehand ROI
perimPos = bwboundaries(newMask, 'noholes');
hf.Position = [perimPos{1}(:,2), perimPos{1}(:,1)];

end