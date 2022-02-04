function [bool, message] = createUnclassifiedClassForGreens(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: July 14, 2021
% NAME: createUnclassifiedClassForGreens (version 1.0)
%
% Iterate through images and put all the predicted green&pink comets into a
% class named "Unclassified".
%
% INPUT:
%   app                 Handles of the application.
%   classID             numeric value [1 255], represent the ID of class on
%                       channel 4
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

bool = 0;
message = {'Process failed.'};

currentImShown = app.comet_handles.IndImgShown;
wb = waitbar(0,'Adding segmented comets to "Unclassified" class. Please wait...');
for i = 1:app.comet_handles.NumImages
    app.comet_handles.IndImgShown = i;
    app.axes1.Children.CData = composeImage(app.comet_handles.Imgs_Stretched(:,:,:,app.comet_handles.IndImgShown));
    set(app.text_Num,'Text', ['Image: ' num2str(i) '/' num2str(app.comet_handles.NumImages)]);
    set(app.text_Name,'Text', ['Image: ' char(app.comet_handles.ImgsNames{i})]);
    pause(0.1)
    waitbar(0,wb,sprintf('Adding segmented comets to "Unclassified" class. Please wait...\n%d / %d images',i,app.comet_handles.NumImages))
    tempIm = app.comet_handles.Imgs_Stretched(:,:,2,i);
    BW2 = tempIm == 255;
    L = bwlabel(BW2);
    numOfObj = max(L,[],'all');
    for j = 1:numOfObj
        waitbar(j/numOfObj,wb,sprintf('Adding segmented comets to "Unclassified" class. Please wait...\n%d / %d images',i,app.comet_handles.NumImages))
        [xend, yend] = find(bwmorph(L == j,'skel',3));
        coor = [yend(1), xend(1)];
        [iscomplete, errorString] = clickOnCometSelection(app, coor);
        if iscomplete == 1
            [bool, warnString] = addComet(app,'Unclassified');
            if bool == 0
                appTextDlg(app, warnString, 'Message', 'error')
                continue
            end
        else
            appTextDlg(app, errorString, 'Corrupted Class structure or segmentation.', 'error')
            app.selectedComet = [];
            app.scope.ImageSource = app.CometIcon;
            app.comet_handles.ROIshown = 0;
            app.comet_handles.ROIori = [];
            app.comet_handles.ROIoriFiltered = [];
            app.comet_handles.ROIsegm = [];
            app.comet_handles.MaskComet = [];
            app.comet_handles.MaskHead = [];
            app.comet_handles.ROI_ULCyx_DRCyx = [];
        end
    end
end
if ishandle(wb), close(wb), end
app.comet_handles.IndImgShown = currentImShown;
app.axes1.Children.CData = composeImage(app.comet_handles.Imgs_Stretched(:,:,:,app.comet_handles.IndImgShown));
set(app.text_Num,'Text', ['Image: ' num2str(currentImShown) '/' num2str(app.comet_handles.NumImages)]);
set(app.text_Name,'Text', ['Image: ' char(app.comet_handles.ImgsNames{currentImShown})]);
app.scope.ImageSource = app.CometIcon;
app.selectedComet = [];
app.comet_handles.ROIshown = 0;
app.comet_handles.ROIori = [];
app.comet_handles.ROIoriFiltered = [];
app.comet_handles.ROIsegm = [];
app.comet_handles.ROI_ULCyx_DRCyx = [];

bool = 1;