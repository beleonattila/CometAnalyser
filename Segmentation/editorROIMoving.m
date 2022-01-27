function editorROIMoving(he, hf)
% TODO

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

% Snap editor ROI to grid
he.Position = round(he.Position);

% Check if the circle ROI's center is inside or outside the freehand ROI.
center = he.Center;
isAdd = hf.inROI(center(1), center(2));
if isAdd
    % Green if inside (since we will add to the freehand).
    he.Color = 'g';
else
    % Red otherwise.
    he.Color = 'r';
end
end