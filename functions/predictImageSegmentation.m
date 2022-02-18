function [bool, message] = predictImageSegmentation(app,method)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% Updated: February 18, 2022
% NAME: predictImageSegmentation (version 1.0)
%
% Performing automatic segmentation by the selected pretrained network.
%   This function modifies the app.comet_handles.Imgs_Streched at the
%   predicted regions.
%   Channel 2 - comet masks get id = 255
%   Channel 3 - head masks get id = 255
%
% INPUT:
%   app                 Handles of the application.
%   method              'single' for the shown image
%                       'multi' for the whole dateset
%                       NOTE: performed on images without manual
%                       segmentation (without red and blue)
%
% OUTPUT:
%   bool                [0 or 1] successor
%   message             Error message of something goes wrong
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
[folderName, ~, ext] = fileparts(app.comet_handles.segmentationOptions.modelPath);
result = isfolder(folderName);
if ~result || ~strcmp(ext,'.mat')
    message = {'Invalid segmentation model. Please select a valid model, then try again!'};
    return
end
try
    message = {'Loading the model, please wait...'};
    dlgHandle = msgbox(sprintf(message{:}),'Training','help');
    sysMem = memory;
    modelFileInfo = dir(app.comet_handles.segmentationOptions.modelPath);
    if sysMem.MaxPossibleArrayBytes < modelFileInfo.bytes
        message = {'Not enough memory to load the Pre-trained Neural Network for segmentation.'};
        return
    end
    load(app.comet_handles.segmentationOptions.modelPath);
    if isempty(who('net'))
        if ishandle(dlgHandle), close(dlgHandle), end
        message = {'Invalid segmentation model. Please select a valid model, then try again!'};
        dlgHandle = msgbox(sprintf(message{:}),'Training','help');
        uiwait(dlgHandle)
        [fileName, path] = uigetfile('Select a pre-trained model!');
        if ischar(path)
            app.comet_handles.segmentationOptions.modelPath = fullfile(path,fileName);
            return
        end
    end
catch me
    if ishandle(dlgHandle), close(dlgHandle), end
    dlgHandle = msgbox(sprintf(me.message),'Training','error');
    uiwait(dlgHandle)
    message = {'Invalid model. Please select a valid model in Segmentation Training Option menu, then try again!'};
    return
end
if ishandle(dlgHandle), close(dlgHandle), end

idx = zeros(app.comet_handles.NumImages,1);
if strcmp(method, 'single')
    if ~any(app.comet_handles.Imgs_Stretched(:,:,2,app.comet_handles.IndImgShown),'all')
        idx(app.comet_handles.IndImgShown,1) = 1;
    end
elseif strcmp(method, 'multi')
%     wb = waitbar(0,'Preparing images');
    n = app.comet_handles.NumImages;
    for j = 1:n
        if ~any(app.comet_handles.Imgs_Stretched(:,:,2,j),'all')
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
                    'Segmentation only works on images without annotation'};
    end
    return
end

memoryRequirement = numel(app.comet_handles.Imgs_Stretched(:,:,1,idx))*5;
imByIm = 0;
env = app.comet_handles.segmentationOptions.ExecutionEnvironment;
if strcmp(env,'auto') || strcmp(env,'gpu') || strcmp(env,'multi-gpu')
    tGPU = gpuDeviceTable;
    if ~isempty(tGPU)
        indx = tGPU.DeviceAvailable == true;
        if sum(indx) > 0
            imByIm = 1;
        else
            if strcmp(env,'gpu') || strcmp(env,'multi-gpu')
                message = {'There is no GPU available.'};
                warndlg(message,'Environment')
            end
            sysMem = memory;
            if sysMem.MaxPossibleArrayBytes < memoryRequirement
                imByIm = 1;
            end
        end
    else
        if strcmp(env,'gpu') || strcmp(env,'multi-gpu')
            message = {'There is no GPU available.'};
            warndlg(message,'Environment')
        end
        sysMem = memory;
        if sysMem.MaxPossibleArrayBytes < memoryRequirement
            imByIm = 1;
        end
    end
elseif strcmp(env,'cpu')
    sysMem = memory;
    if sysMem.MaxPossibleArrayBytes < memoryRequirement
        imByIm = 1;
    end
end

inputSize = net.Layers(1).InputSize;
OrigImageSize = size(app.comet_handles.Imgs_Stretched(:,:,1,1));
    
if imByIm == 0
    
    tempIm = app.comet_handles.Imgs_Stretched(:,:,1,idx);
    I = cat(3,tempIm,tempIm,tempIm);
    clear('tempIm');
    
    imageSize = OrigImageSize;
    padSize = zeros(1,2);
    if any(inputSize(1:2) ~= imageSize(1:2))
        
        warndlg('The image size in this project is not identical to the input size of the segmentation model. This can cause performance drop.');
        imSizeDiff = inputSize(1:2) - imageSize(1:2);
        
        % If the project images are larger
        if any(imSizeDiff<0)
            [~,ImMinIdx] = min(imSizeDiff);
            imScaler = [nan nan];
            imScaler(ImMinIdx) = inputSize(ImMinIdx);
            I = imresize(I,imScaler);
            imageSize = size(I);
            imSizeDiff = inputSize(1:2) - imageSize(1:2);
        end
        
        % If the project images are smaller
        
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
    clear('net')
    clear('I')
    C8 = uint8(C);
    clear('C')
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
    C8 = imresize(C8,OrigImageSize(1:2));
    C8(C8 == 3) = 0;
    BW = imbinarize(C8);
    BW_fill = imfill(BW, 4, 'holes');
    BW_open = bwareaopen(BW_fill,250,4);
    se = strel('disk',20);
    BW2 = imclose(BW_open,se);
    C8(~BW2) = 0;
    segmentedComet = uint8(BW2) * 255;
    segmentedHead = C8;
    segmentedHead(C8 == 1) = 255;
    segmentedHead(segmentedHead~=255) = 0;
    clear('C8')

    app.comet_handles.Imgs_Stretched(:,:,2,idx) = segmentedComet;
    app.comet_handles.Imgs_Stretched(:,:,3,idx) = segmentedHead;
    delete(progressfig)
else
    wb = waitbar(0,'Segmentation in progress. Please wait...');
    numIm2Segmentation = sum(idx);
    idx2 = find(idx);
    for i = 1:sum(idx)
        tempIm = app.comet_handles.Imgs_Stretched(:,:,1,idx2(i));
        I = cat(3,tempIm,tempIm,tempIm);
        clear('tempIm');
        
        imageSize = OrigImageSize;
        padSize = zeros(1,2);
        if any(inputSize(1:2) ~= imageSize(1:2))
            if i == 1
                warndlg('The image size in this project is not identical to the input size of the segmentation model. This can cause performance drop.');
            end
            imSizeDiff = inputSize(1:2) - imageSize(1:2);
            
            % If the project images are larger
            if any(imSizeDiff<0)
                [~,ImMinIdx] = min(imSizeDiff);
                imScaler = [nan nan];
                imScaler(ImMinIdx) = inputSize(ImMinIdx);
                I = imresize(I,imScaler);
                imageSize = size(I);
                imSizeDiff = inputSize(1:2) - imageSize(1:2);
            end
            
            % If the project images are smaller
            
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
        
        [C, ~, ~] = semanticseg(I, net);
        clear('I')
        C8 = uint8(C);
        clear('C')
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
        C8 = imresize(C8,OrigImageSize(1:2));
        C8(C8 == 3) = 0;
        BW = imbinarize(C8);
        BW_fill = imfill(BW, 4, 'holes');
        BW_open = bwareaopen(BW_fill,250,4);
        se = strel('disk',20);
        BW2 = imclose(BW_open,se);
        C8(~BW2) = 0;
        segmentedComet = uint8(BW2) * 255;
        segmentedHead = C8;
        segmentedHead(C8 == 1) = 255;
        segmentedHead(segmentedHead~=255) = 0;
        clear('C8')
        
        app.comet_handles.Imgs_Stretched(:,:,2,idx2(i)) = segmentedComet;
        app.comet_handles.Imgs_Stretched(:,:,3,idx2(i)) = segmentedHead;
        if ishandle(wb)
            waitbar(i/numIm2Segmentation,wb,sprintf('Segmentation in progress. Please wait...\n %d / %d',[i,numIm2Segmentation]))
        end
    end
    if ishandle(wb), close(wb), end
end
message = {'Segmentation done.';...
            '';...
            [num2str(sum(idx)),' image(s) have been segmented.']};
bool = 1;