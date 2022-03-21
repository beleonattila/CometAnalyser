function Table = computeFeatures(Maski_Origj, Maski_Cometj, Maski_Tailj,Maski_Headj, Maski_Classj, Imgi_Name, Intensity_MinMax_StretchedOrig, Cellj,ULC, DRC, centroid)
% AUTHOR: Filippo Piccinini (E-mail: filippo.piccinini85@gmail.com)
% DATE: April 14, 2017
% Updated: March 14, 2022 (Attila Beleon)
% NAME: computeFeatures (version 1.0)
%
% To compute features starting from the mask of comet, head, ...
%
% PARAMETERS:
% Maski_Origj                    -  Mask of the original image.
% Maski_Cometj                   -  Mask of the Comet.
% Maski_Headj                    -  Mask of the Head.
% Maski_Classj                   -  Class of the Comet.
% Imgi_Name                      -  Name of the original image.
% Cellj                          -  ID of the Comet analysed.
% Intensity_MinMax_StretchedOrig -  Intesity values of the stretched and
%                                   original images, in order min, max.
% ULC                            -  Upper left corner of the bounding box
% DRC                            -  Down Right Corner of the bounding box
% centroid                       -  Center point of the mask
%
%
% OUTPUT:
% parameters Output features.
%
% EXAMPLE OF USAGE:
% parameters = computeFeatures(Maski_Origj, Maski_Cometj, Maski_Tailj,
%            Maski_Headj, Maski_Classj, Imgi_Name, [0, 255, 0, 255], Cellj)
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
Table.ImageName = char(Imgi_Name);
Table.CometID = Cellj;
Table.CometClass = Maski_Classj;
Table.centroidX = centroid(1);
Table.centroidY = centroid(2);
Table.xL = ULC(1);
Table.xH = DRC(1);
Table.yL = ULC(2);
Table.yH = DRC(2);
InFunctionFolder1 = "DATAtoBeExtracted";

% Check functions
if isdeployed
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
else
    FunctionList = dir(fullfile(InFunctionFolder1, 'data_*.m'));
    if isempty(FunctionList)
        error(['Please, remember to manually copy the folder named ',...
            '"DATAtoBeExtracted" (it is a folder containing several .m files ',...
            'and it is provided together with the installation-files of CometAnalyser) ',...
            'in the same path where the AnaSP-launcher is located.'])
    else
        dirFunctionList_length = length(FunctionList);
    end
    
    if dirFunctionList_length < 1
        error(['Please, remember to manually copy the folder named ',...
            '"DATAtoBeExtracted" (it is a folder containing several .m files ',...
            'and it is provided together with the installation-files of CometAnalyser) ',...
            'in the same path where the AnaSP-launcher is located.'])
    end
end

for FunNum = 1:length(FunctionList)
    try
        if isdeployed
            functionNameNum = FunctionList{FunNum};
        else
            functionNameNum = FunctionList(FunNum).name;
            functionNameNum = functionNameNum(1:end-2);
        end
        Value = feval(functionNameNum, Maski_Origj, Maski_Cometj, Maski_Tailj, Maski_Headj, Intensity_MinMax_StretchedOrig);
        Table.(functionNameNum){1,1} = Value;
    catch ME
        errorString = [ME.message];
        msgbox(sprintf(errorString));
        return
    end
end