function centroid = calcLargestInnerTriangleCentorid(mask)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: February 17, 2022
% Updated: February 17, 2022
% NAME: calcLargestInnerTriangleCentorid (version 1.0)
%
% Calculation a centroid for an object alternatively.
%
% INPUT:
%   mask                Binary image of the object
%
% OUTPUT:
%   centroid            X,Y coordiantes
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

BW = bwperim(mask);
[x,y] = find(BW);
dT = delaunay(x,y);
xT = reshape(x(dT), size(dT)); % X coordinates of vertices in triangulation
yT = reshape(y(dT), size(dT)); % Y coordinates of vertices in triangulation
areaT = abs((xT(:, 2) - xT(:, 1)) .* (yT(:, 3) - yT(:, 1)) - ...
    (xT(:, 3) - xT(:, 1)) .* (yT(:, 2) - yT(:, 1)))/2;

centroidTri = round([mean(xT,2) mean(yT,2)]);
[~, sortedID] = sort(areaT);

for i = 1:numel(sortedID)
    if mask(centroidTri(sortedID(i),1),centroidTri(sortedID(i),2)) > 0
        centroid = centroidTri(sortedID(i),:);
        break
    end
end