function OutValue = data_Tail_Area_inPixels(Maski_Origj, Maski_Cometj, Maski_Tailj, Maski_Headj, Intensity_MinMax_StretchedOrig)
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
%   Intensity_MinMax_StretchedOrig  Intesity values of the stretched and
%                       original images, in order min, max.
 
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

Mask = Maski_Tailj;
if sum(Mask(:))>1      
%     [MaskMaxTailj, RotationAngle, Comet_Centroid_yrow, Comet_Centroid_xcol] = ComputeMaskMaxTailj(Maski_Cometj, Maski_Tailj, Maski_Headj);
%     Values = struct2cell(regionprops(MaskMaxTailj,'Area'));
%     OutValue = Values{1};
    OutValue = sum(Maski_Tailj,'all');
else
    OutValue = 0;
end