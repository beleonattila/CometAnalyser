function tempIm = classFilteredImage(im, cLabel, score, cnum, classNames, BB)
% TODO comment and header

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
   cBB = BB{i} + [-1 1; 1 -1];
   position(i,:) = [cBB(2,2) cBB(1,1) cBB(1,2)-cBB(2,2) cBB(2,1)-cBB(1,1)];
   imLabel{i} = [cLabel{i} '_|_' num2str(score(i,cnum(i)))];
   labelColor(i,:) = colorOrder(end - cnum(i),:)*255;
end

tempIm = insertObjectAnnotation(im,'rectangle',position,imLabel,'LineWidth',3,'Color',labelColor,'TextColor','black','FontSize',20);
