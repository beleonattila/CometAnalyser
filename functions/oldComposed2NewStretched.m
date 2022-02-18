function Imgs_Stretched = oldComposed2NewStretched(Imgs_Composed)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: February 4, 2021
% Updated: February 18, 2022
% NAME: oldComposed2NewStretched (version 1.0)
%
% Converting the old Composed to new Stretched version and removing the
% small high intensity dots that considered noise.
%
% INPUT:
%   Imgs_Composed       Old version of image storage RGB + class channel
%
% OUTPUT:
%   Imgs_Stretched      New version of image storage grey scale + 2 class
%                       channels
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

Imgs_Stretched = Imgs_Composed(:,:,2,:);

cometHeads = Imgs_Composed(:,:,3,:);
cometHeads(cometHeads<255) = 0;
cometHeads2 = bwareaopen(logical(cometHeads), 10);
Imgs_Stretched(:,:,3,:) = cometHeads2*255;

cometMasks = Imgs_Composed(:,:,1,:);
cometMasks(cometMasks<255) = 0;
cometMasks2 = bwareaopen(logical(cometMasks), 10);
Imgs_Stretched(:,:,2,:) = cometMasks2*255;
Imgs_Stretched(:,:,2,:) = Imgs_Stretched(:,:,2,:) + Imgs_Stretched(:,:,3,:);