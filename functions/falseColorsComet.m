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
 
% Copyright © 2015 Filippo Piccinini 
% Istituto Scientifico Romagnolo per lo Studio e la Cura dei Tumori (IRST) 
% IRCCS, Meldola (FC), Italy. All rights reserved.
%
% This program is free software; you can redistribute it and/or modify it 
% under the terms of the GNU General Public License version 2 (or higher) 
% as published by the Free Software Foundation. This program is 
% distributed WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
% General Public License for more details.

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