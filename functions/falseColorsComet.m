function [ROIcomposed] = falseColorsComet(ROIori, MaskHead, MaskComet, flag_CurrentCometType)
% AUTHOR: Filippo Piccinini (E-mail: filippo.piccinini85@gmail.com)
% DATE: March 22, 2017
% NAME: falseColorsComet (version 1.0)
% 
% Selected comet visualized in false colors: gray original image, blue
% nuclei, red comed tail region.
%
% PARAMETERS:
% 	ROIori              Original image.
%   flag_CurrentCometType   1: without tail; 2: without head; with tail and
%                           head.
%
% OUTPUT:
%   ROIcomposed         Output RGB image.
%
% EXAMPLE OF USAGE:
%   ROIcomposed = falseColorsComet(Img, 3);
 
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

MaskComet(MaskComet>0) = 1;
if ~isempty(MaskHead)
    MaskHead = MaskHead.*MaskComet;
end

[yrowROI, xcolROI, chROI, cht] = size(ROIori);
ROIcomposed = zeros(yrowROI, xcolROI, 3);
ROIcomposed(:,:,1) = ROIori;
ROIcomposed(:,:,2) = ROIori;
ROIcomposed(:,:,3) = ROIori;
ROIcomposed1 = ROIcomposed(:,:,1);
ROIcomposed1(MaskComet>0)=255;
ROIcomposed(:,:,1) = ROIcomposed1;
if flag_CurrentCometType == 1 || flag_CurrentCometType == 3       
    ROIcomposed3 = ROIcomposed(:,:,3);
    ROIcomposed3(MaskHead>0)=255;
    ROIcomposed(:,:,3) = ROIcomposed3;
    ROIcomposed1 = ROIcomposed(:,:,1);
    ROIcomposed1(MaskHead>0)=ROIori(MaskHead>0);
    ROIcomposed(:,:,1) = ROIcomposed1;
end