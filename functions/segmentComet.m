function [MaskBW, BWthreshold] = segmentComet(Img, ManualSegmBW, ThreshAdditiveFactor, SizeDiskDilation, flag_ThresholdMode)
% AUTHOR: Filippo Piccinini (E-mail: filippo.piccinini85@gmail.com)
% DATE: March 14, 2017
% Updated: February 18, 2022 (Attila Beleon)
% NAME: segmentComet (version 1.0)
% 
% To segment the comet region.
%
% INPUT:
% 	Img                 Original image.
%   ManualSegmBW        FG manually segmented.
%   ThreshAdditiveFactor Input additive factor for threshold.
%   SizeDiskDilation    Size of the dilation.
%   flag_ThresholdMode  The decide which automatic threshold modality use.
%                       1=Otsu, 2=Triangle, 3=average between Otsu and
%                       Triangle.
%
% OUTPUT:
%   MaskBW              Output binary mask.
%
% EXAMPLE OF USAGE:
%   Mask = segmentComet(Img, MaskOri);
 
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

if nargin<5
    flag_ThresholdMode = 1;
end
if nargin<4
    flag_ThresholdMode = 1;
    SeDiskDilation = 0;
end
if nargin<3
    flag_ThresholdMode = 1;
    SeDiskDilation = 0;
    ThreshAdditiveFactor = 0;
end

ManualSegmBW = uint8(ManualSegmBW);
imageComulative = Img(:);

% Automatic threshold
if flag_ThresholdMode == 0
    % Fit freehand selection
    BWthreshold = 0;
    BinThresh = 0;
elseif flag_ThresholdMode == 1
    % Otsu
    [BWthreshold, EffectivenessMetric] = graythresh(imageComulative);
elseif flag_ThresholdMode == 2
    % Triangle
    [counts, binLocations] = imhist(imageComulative);
    HistoCountVector = counts;
    PeakRightOrLeft = 'Left';
    TailRightOrLeft = 'Right';
    version = 0;
    BinThresh = HistoTriangleThreshold(HistoCountVector, PeakRightOrLeft, TailRightOrLeft, version);
    BWthreshold = binLocations(BinThresh)/length(binLocations);
else
    % Average between Otsu and Triangle
    [BWthresholdOtsu, EffectivenessMetric] = graythresh(imageComulative);
    [counts, binLocations] = imhist(imageComulative);
    HistoCountVector = counts;
    PeakRightOrLeft = 'Left';
    TailRightOrLeft = 'Right';
    version = 0;
    BinThresh = HistoTriangleThreshold(HistoCountVector, PeakRightOrLeft, TailRightOrLeft, version);
    BWthresholdTriangle = binLocations(BinThresh)/length(binLocations);
    BWthreshold = (BWthresholdOtsu+BWthresholdTriangle)/2;
end

% Mask creation
BinThresh = BWthreshold*255;
BinThresh = BinThresh + ThreshAdditiveFactor;
if BinThresh<0
    BinThresh = 0;
end
if BinThresh>255
    BinThresh = 255;
end
BWthreshold = BinThresh/255;
if BWthreshold<0; BWthreshold=0; elseif BWthreshold>255; BWthreshold=255; end
MaskBW01 = uint8(imbinarize(Img,BWthreshold));

% Pixels out of the original segmentation
ManualSegmBW(ManualSegmBW>1) = 1;
MaskBW01 = MaskBW01.*ManualSegmBW;

% Dilation and hole filling.
SeDiskDefault = strel('disk', 5);
MaskBW01 = imdilate(MaskBW01,SeDiskDefault);
MaskBW01 = imfill(MaskBW01,'holes');
MaskBW01 = imerode(MaskBW01,SeDiskDefault);
if SizeDiskDilation>0
    SeDiskDilation = strel('disk', SizeDiskDilation);
    MaskBW01 = imdilate(MaskBW01,SeDiskDilation);
end

% Keep only the maximum object
[ImLabels, numObj] = bwlabel(MaskBW01);
Objs = regionprops(ImLabels,'Area');
Objs_Area = [Objs(:).Area]';
[AreaObjectsSort, AreaObjectsSortInd] = sort(Objs_Area);
if ~isempty(AreaObjectsSort)
    MaskBW01 = bwareaopen(MaskBW01,max(AreaObjectsSort));
end
MaskBW01 = uint8(MaskBW01);

% From input
if SizeDiskDilation>0
    SeDiskDefault = strel('disk', SizeDiskDilation);
    MaskBW01 = imdilate(MaskBW01,SeDiskDefault);
end

% Pixels out of the original segmentation
ManualSegmBW(ManualSegmBW>1) = 1;
MaskBW01 = MaskBW01.*ManualSegmBW;

MaskBW = MaskBW01;