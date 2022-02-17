function [iscomplete, errorString] = selecCometFunction(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 20, 2021
% NAME: selecCometFunction (version 1.0)
% 
% Performing the method of comet selection from shown image by drawing a
% poligon or click on a presegmented comet to load into the scope for
% manual segmentation or to perform class operations. (add or remove)
%
% INPUT:
%   app                 Handles of the application.          
%
% OUTPUT:
%   iscomplete          Succes indicator bool
%   errorString         Error message if something goes wrong
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

iscomplete = 0;
app.selectedComet = [];
app.scope.ImageSource = app.CometIcon;
app.comet_handles.ROIshown = 0;
app.comet_handles.ROIori = [];
app.comet_handles.ROIoriFiltered = [];
app.comet_handles.ROIsegm = [];
app.comet_handles.MaskComet = [];
app.comet_handles.MaskHead = [];
app.comet_handles.ROI_ULCyx_DRCyx = [];
app.comet_handles.CurrentCometHead_YrowXcol = [];

xcolOri = app.comet_handles.ImageSize(1);
yrowOri = app.comet_handles.ImageSize(2);

% Manual selection with freehand selection
try
    
    % New version: multiple-selection
    % New version from: http://stackoverflow.com/questions/23463516/draw-multiple-regions-on-an-image-imfreehand
    clear BWout1
    hFigFree2 = drawfreehand(app.axes1);
    pos = hFigFree2.Position;
    if numel(pos)<5
        if exist('hFigFree2', 'var'); delete(hFigFree2); end
        errorString = {'Incorrect selection.'};
        iscomplete = 0;
        return
    end
    
    % If a right ROI has been selected, this gives the opportunity to move the ROI
    wait( hFigFree2 );
    % Check on the minimum number of pixels of the ROI selected
    if ~isvalid(hFigFree2) || numel(find(createMask(hFigFree2)==1))<=app.comet_handles.ROIminNumPixels
        errorString = {'The selected region is too small!'};
        if exist('hFigFree2', 'var'); delete(hFigFree2); end
    else
        BWout1 = createMask(hFigFree2)*1;

        pos = hFigFree2.Position;
        xHi = round(min([max(pos(:,2)); xcolOri]));
        yHi = round(min([max(pos(:,1)); yrowOri]));
        xLow = round(max([min(pos(:,2)); 1]));
        yLow = round(max([min(pos(:,1)); 1]));
        BB = [xLow, yHi;...
            xHi, yLow];
        
        % Delete line
        if exist('hFigFree2', 'var'); delete(hFigFree2); end
        classLayer = app.comet_handles.Imgs_Stretched(:,:,2,app.comet_handles.IndImgShown);
        selecttionOnClassLayer = classLayer .* uint8(BWout1);
        NumOfSelectedObjects = numel(setdiff(unique(bwlabel(logical(selecttionOnClassLayer))),0));
        
        if NumOfSelectedObjects <= 1
        [bool, errorString] = ROI_processing(app, BB, BWout1, []);
        
        if bool == 0
            if isempty(errorString)
                errorString = {'No comet has been detected.'};
            end
            iscomplete = 0;
            return
        end
        iscomplete = 1;
        else
            errorString = {'More than one objects have been selected.';...
                        'Please select only one object!'};
            iscomplete = 0;
            return
        end
    end
catch ME
    iscomplete = 0;
    errorString = {'Wrong segmentation.';'';'';'Error description:';'';ME.message};
end