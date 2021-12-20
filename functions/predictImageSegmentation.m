function [bool, message] = predictImageSegmentation(app,method)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% NAME: predictImageSegmentation (version 1.0)
%
% Performing automatic segmentation by the selected pretrained network.
%
% INPUT:
%   app                 Handles of the application.
%   method              'single' for the shown image
%                       'multi' for the whole dateset
%                       NOTE: performed on images without manual
%                       segmentation (without red and blue)
%
% OUTPUT:
%   This function modifies the app.comet_handles.Imgs_Composed at the
%   predicted regions.
%   Channel 1 to 3 will be modified to achieve pink and green colours
%   Channel 4 to highlight that it's a prediction as class ID of 255
%
%
% Copyright © 2021 Filippo Piccinini
% Istituto Scientifico Romagnolo per lo Studio e la Cura dei Tumori (IRST)
% IRCCS, Meldola (FC), Italy. All rights reserved.
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License version 2 (or higher)
% as published by the Free Software Foundation. This program is
% distributed WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.

bool = 0;
try
    message = {'Loading the model, please wait...'};
    dlgHandle = msgbox(sprintf(message{:}),'Training','help');
    load(app.comet_handles.segmentationOptions.modelPath);
    if isempty(who('net'))
        if ishandle(dlgHandle), close(dlgHandle), end
        message = {'Invalid model. Please select a valid model, then try again!'};
        dlgHandle = msgbox(sprintf(message{:}),'Training','help');
        uiwait(dlgHandle)
        [fileName, path] = uigetfile('Select a pre-trained model!');
        if ischar(path)
            app.comet_handles.segmentationOptions.modelPath = fullfile(path,fileName);
            bool = 1;
            return
        end
    end
catch me
    if ishandle(dlgHandle), close(dlgHandle), end
    dlgHandle = msgbox(sprintf(me.message),'Training','error');
    uiwait(dlgHandle)
    message = {'Invalid model. Please select a valid model in Segmentation Option menu, then try again!'};
    return
end
if ishandle(dlgHandle), close(dlgHandle), end



idx = zeros(app.comet_handles.NumImages,1);
if strcmp(method, 'single')
    if ~any(app.comet_handles.Imgs_Composed(:,:,4,app.comet_handles.IndImgShown),'all')
        idx(app.comet_handles.IndImgShown,1) = 1;
    end
elseif strcmp(method, 'multi')
%     wb = waitbar(0,'Preparing images');
    n = app.comet_handles.NumImages;
    for j = 1:n
        if ~any(app.comet_handles.Imgs_Composed(:,:,4,j),'all')
            idx(j,1) = 1;
%             if ishandle(wb)
%                 wb = waitbar(j/n,wb,'Preparing images');
%             end
        end
    end
%     if ishandle(wb), close(wb), end
end


idx = logical(idx);
if ~any(idx)
    if strcmp(method, 'single')
        message = {'The current image contains annotations: it will be not analysed'};
    else
        message = {'There is no blank image to do segmentation.';...
                    '';...
                    'Segmentation only works on images with out annotation'};
    end
    return
end
tempIm = app.comet_handles.Imgs_Stretched(:,:,1,idx);
I = cat(3,tempIm,tempIm,tempIm);

inputSize = net.Layers(1).InputSize;
imageSize = size(I);

if any(inputSize(1:2) ~= imageSize(1:2))
    warndlg('The image size in this project not identical with the ipnut size of the segmentational model, which can cause performance drop.');
    imSizeDiff = inputSize(1:2) - imageSize(1:2);
    padSize = zeros(1,2);
    if imSizeDiff(1)
        if imSizeDiff(1)>0
            padSize(1) = imSizeDiff(1);
        end
    end
    
    if imSizeDiff(2)
        if imSizeDiff(2)>0
            padSize(2) = imSizeDiff(2);
        end
    end

    I = padarray(I,round(padSize./2),0,'both');
    I = imresize(I,inputSize(1:2));
end


progressfig = uifigure;
uiprogressdlg(progressfig,'Title','Performing prediction. Please wait...',...
        'Indeterminate','on');
pause(2)

[C, ~, ~] = semanticseg(I, net);
C8 = uint8(C);
if any(padSize)
    if padSize(1)
        C8(1:round(padSize(1)./2),:,:) = [];
        C8(end-round(padSize(1)./2):end,:,:) = [];
    end
    if padSize(2)
        C8(:,1:round(padSize(2)./2),:) = [];
        C8(:,end-round(padSize(2)./2):end,:) = [];
    end
end
C8 = imresize(C8,imageSize(1:2));
C8(C8 == 3) = 0;
BW = imbinarize(C8);
BW_fill = imfill(BW, 4, 'holes');
BW_open = bwareaopen(BW_fill,250,4);
se = strel('disk',20);
BW2 = imclose(BW_open,se);
C8(~BW2) = 0;
green = uint8(BW2) * 255;
green(C8==1) = 0;
magenta = C8;
magenta(C8 == 1) = 255;
magenta(magenta~=255) = 0;


app.comet_handles.Imgs_Composed(:,:,2,idx) = app.comet_handles.Imgs_Composed(:,:,2,idx) + permute(green,[1 2 4 3]);
app.comet_handles.Imgs_Composed(:,:,1,idx) = app.comet_handles.Imgs_Composed(:,:,1,idx) + permute(magenta,[1 2 4 3]);
app.comet_handles.Imgs_Composed(:,:,3,idx) = app.comet_handles.Imgs_Composed(:,:,3,idx) + permute(magenta,[1 2 4 3]);
app.comet_handles.Imgs_Composed(:,:,4,idx) = app.comet_handles.Imgs_Composed(:,:,4,idx) + permute(magenta,[1 2 4 3]) + permute(green,[1 2 4 3]);

delete(progressfig)

message = {'Segmentation done.';...
            '';...
            [num2str(sum(idx)),' image(s) have been segmented.']};
bool = 1;