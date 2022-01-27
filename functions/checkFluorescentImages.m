function flagEstimated_FluorescenceImages = checkFluorescentImages(referenceFrame)
% AUTHOR: Filippo Piccinini (E-mail: f.piccinini@unibo.it)
% DATE: March 08, 2018
% NAME: checkFluorescentImages (version 1.0)
% 
% To check if the input images are fluorescent images or not.
%
% PARAMETERS:
%   referenceFrame      An image to be checked.
%
% OUTPUT:
%   flagEstimated_FluorescenceImages    Estimated flag: 1 if it is supposed
%                                       that the image is a fluorescent
%                                       one, 0 otherwise.
%
% EXAMPLE OF USAGE: 
 
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

[counts, binLocations] = imhist(referenceFrame);
HistoCountVector_Ori = counts;
%figure, plot(HistoCountVector_Ori);

windowSize = 5; 
coefb = (1/windowSize)*ones(1,windowSize);
coefa = 1;
HistoCountVector_Fil = filter(coefb,coefa,HistoCountVector_Ori);

[MaxPeak_Val, MaxPeak_Pos]  = max(HistoCountVector_Fil);
HistoCountVector_Fil_LeftTail = HistoCountVector_Fil(1:MaxPeak_Pos);
HistoCountVector_Fil_RightTail = HistoCountVector_Fil(MaxPeak_Pos:end);
[MinLeftTail_Val, MinLeftTail_Pos]  = min(HistoCountVector_Fil_LeftTail);
[MinRightTail_Val, MinRightTail_Pos]  = min(HistoCountVector_Fil_RightTail);

lengthLeftTail = MaxPeak_Pos-MinLeftTail_Pos;
lengthRightTail = (MinRightTail_Pos+MaxPeak_Pos)-MaxPeak_Pos;

if lengthLeftTail<lengthRightTail
    flagEstimated_FluorescenceImages = 1;
else
    flagEstimated_FluorescenceImages = 0;
end