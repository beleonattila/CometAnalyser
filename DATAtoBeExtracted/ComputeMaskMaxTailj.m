function [MaskMaxTailj, RotationAngle, Comet_Centroid_yrow, Comet_Centroid_xcol] = ComputeMaskMaxTailj(Maski_Cometj, Maski_Tailj, Maski_Headj)
% AUTHOR: Filippo Piccinini (E-mail: filippo.piccinini85@gmail.com)
% DATE: April 14, 2017
% NAME: TemplateFunction (version 1.0)
% 
% To extract data from masks.
% NOTE: the first four letters of the name of this function must be: data_.
%
% PARAMETERS:
% 	Maski_Origj         Mask of the original image.
%   Maski_Cometj        Mask of the Comet.
%   Maski_Tailj         Mask of the Tail
%   Maski_Headj         Mask of the Head.
 
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
  
% Orientation from Comet controid to Head centroid
Comet_Centroid  = regionprops(Maski_Cometj, 'Centroid');
Comet_CentroidXY = Comet_Centroid(1).Centroid;
Comet_Centroid_xcol = Comet_CentroidXY(1,1);
Comet_Centroid_yrow = Comet_CentroidXY(1,2);
if max(Maski_Headj(:))<1
    MaskMaxTailj = Maski_Tailj;
    RotationAngle = 0;
    return
end
Head_Centroid  = regionprops(Maski_Headj, 'Centroid');
Head_CentroidXY = Head_Centroid(1).Centroid;
Head_Centroid_xcol = Head_CentroidXY(1,1);
Head_Centroid_yrow = Head_CentroidXY(1,2);

[RotationAngle, Module] = AngleBetweenTwoPoints([Comet_Centroid_xcol, Comet_Centroid_yrow], [Head_Centroid_xcol, Head_Centroid_yrow]);
Maski_Cometj_Rotated = rotateAround(Maski_Cometj, Comet_Centroid_yrow, Comet_Centroid_xcol, -RotationAngle);
Maski_Headj_Rotated = rotateAround(Maski_Headj, Comet_Centroid_yrow, Comet_Centroid_xcol, -RotationAngle);
Maski_Tailj_Rotated = rotateAround(Maski_Tailj, Comet_Centroid_yrow, Comet_Centroid_xcol, -RotationAngle);

[Cometj_yrow, Cometj_xcol] = find(Maski_Cometj_Rotated==1);
Cometj_yrowmin = min(Cometj_yrow); Cometj_yrowmax = max(Cometj_yrow);
Cometj_xcolmin = min(Cometj_xcol); Cometj_xcolmax = max(Cometj_xcol);

[Headj_yrow, Headj_xcol] = find(Maski_Headj_Rotated==1);
Headj_yrowmin = min(Headj_yrow); Headj_yrowmax = max(Headj_yrow);
Headj_xcolmin = min(Headj_xcol); Headj_xcolmax = max(Headj_xcol);

LengthLeftSide  = abs(Headj_xcolmin-Cometj_xcolmin);
LengthRightSide = abs(Headj_xcolmax-Cometj_xcolmax);
MaskMaxTailj = Maski_Tailj_Rotated;

if LengthLeftSide>LengthRightSide
    MaskMaxTailj(:,Headj_xcolmin:end) = 0;
else
    MaskMaxTailj(:,1:Headj_xcolmax) = 0;
end
if sum(MaskMaxTailj)==0
    props = regionprops('table',imbinarize(Maski_Tailj_Rotated),'Area','PixelList','PixelIdxList');
    idx = find(max(props.Area));
    MaskMaxTailj(props.PixelIdxList{idx}) = 1;
end
MaskMaxTailj = rotateAround(MaskMaxTailj, Comet_Centroid_yrow, Comet_Centroid_xcol, RotationAngle);