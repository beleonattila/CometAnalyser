function  Table = computeFeatures(Maski_Origj, Maski_Cometj, Maski_Tailj, Maski_Headj, Maski_Classj, Imgi_Name, Intensity_MinMax_StretchedOrig, Cellj, ULC, DRC, centroid)
% AUTHOR: Filippo Piccinini (E-mail: filippo.piccinini85@gmail.com)
% DATE: April 14, 2017
% Updated:  February 18, 2022 (Attila Beleon)
% NAME: computeFeatures (version 1.0)
% 
% To compute features starting from the mask of comet, head, ...
%
% PARAMETERS:
% 	Maski_Origj         Mask of the original image.
%   Maski_Cometj        Mask of the Comet.
%   Maski_Headj         Mask of the Head.
%   Maski_Classj        Class of the Comet.
%   Imgi_Name           Name of the original image.
%   Cellj               ID of the Comet analysed.
%   Intensity_MinMax_StretchedOrig  Intesity values of the stretched and
%                       original images, in order min, max.
%
%
% OUTPUT:
%   parameters          Output features.
%
% EXAMPLE OF USAGE:
%   parameters = computeFeatures(Maski_Origj, Maski_Cometj, Maski_Tailj, Maski_Headj, Maski_Classj, Imgi_Name, [0, 255, 0, 255], Cellj)
 
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

% Check if there are functions
Table.ImageName{1,1}  = char(Imgi_Name);
Table.CometID{1,1}    = Cellj;
Table.CometClass{1,1} = Maski_Classj;
Table.centroidX = centroid(1);
Table.centroidY = centroid(2);
Table.xL = ULC(1);
Table.xH = DRC(1);
Table.yL = ULC(2);
Table.yH = DRC(2);

FunctionList = {'data_Comet_Area_inPixels';...
    'data_Comet_Max_Length_inPixels';...
    'data_Comet_Mean_Intensity';...
    'data_Comet_Sphericity';...
    'data_Comet_Std_Intensity';...
    'data_Comet_Sum_Intensities';...
    'data_Head_Area_inPixels';...
    'data_Head_Max_Length_inPixels';...
    'data_Head_Mean_Intensity';...
    'data_Head_PercentDNA';...
    'data_Head_Sphericity';...
    'data_Head_Std_Intensity';...
    'data_Head_Sum_Intensities';...
    'data_Tail_Area_inPixels';...
    'data_Tail_Extent_Moment';...
    'data_Tail_Length_Max_Direction_Line_inPixels';...
    'data_Tail_Mean_Intensity';...
    'data_Tail_Olive_Moment';...
    'data_Tail_PercentDNA';...
    'data_Tail_Std_Intensity';...
    'data_Tail_Sum_Intensities'};

for FunNum = 1:length(FunctionList)
    try
        Value = feval(FunctionList{FunNum}, Maski_Origj, Maski_Cometj, Maski_Tailj, Maski_Headj, Intensity_MinMax_StretchedOrig);
        Table.(FunctionList{FunNum}){1,1} = Value;
    catch ME
        errorString = [ME.message];
        msgbox(sprintf(errorString));
        return
    end
end