function tempIm = classFilteredImage(im, mask, cLabel, score, cnum, classNames, cometIDs)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: September 13, 2021
% Updated: February 17, 2022
% NAME: classFilteredImage (version 1.0)
%
% Applying colorized bounding boxes with texts on an image, based on the
% classigication results.
%
% INPUT:
%   im                  RGB image
%   mask                Binary image of the object
%   cLabel              Array containing ID of calsses as prediction result
%   score               Score of the classification by each instances
%   cnum                Number of cells
%   classNames          Cell contiaing strings of class names
%   cometIDs            Array contains the IDs of each comets
%
% OUTPUT:
%   tempIm              Image with labels on it
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

n = numel(classNames);
colorOrder = jet(n+2);
position = zeros(length(cnum),4);
imLabel = cell(length(cnum),1);
labelColor = zeros(length(cnum),3);
for i = 1:length(cnum)
    [xCoor,yCoor] = find(mask == cometIDs(i));
    xMin = min(xCoor)-1;
    xMax = max(xCoor)+1;
    yMin = min(yCoor)-1;
    yMax = max(yCoor)+1;
    position(i,:) = [yMin, xMin, yMax-yMin, xMax-xMin];
    imLabel{i} = [cLabel{i} '_|_' num2str(score(i,cnum(i)))];
   labelColor(i,:) = colorOrder(end - cnum(i),:)*255;
end

tempIm = insertObjectAnnotation(im,'rectangle',position,imLabel,'LineWidth',3,'Color',labelColor,'TextColor','black','FontSize',20);
