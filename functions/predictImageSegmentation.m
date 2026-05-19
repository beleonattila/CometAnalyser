function [bool, message] = predictImageSegmentation(app, method)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% Updated: May 01, 2026
% NAME: predictImageSegmentation (version 2.0)
%
% Automatic segmentation using pre-trained U-Net with sliding window
% inference, followed by morphological post-processing and watershed
% splitting of touching comets.
%
% Post-processing reuses segmentComet and segmentHead for consistency
% with the manual segmentation pipeline.
%
% INPUT:
%   app     App handles
%   method  'single' — segment current image only
%           'multi'  — segment all unannotated images
%
% OUTPUT:
%   bool    1 on success, 0 on failure
%   message Cell array of status/error messages

bool    = 0;
message = [];

% -------------------------------------------------------------------------
% Validate model path
% -------------------------------------------------------------------------
[folderName, ~, ext] = fileparts(app.comet_handles.segmentationOptions.modelPath);
if ~isfolder(folderName) || ~strcmp(ext, '.mat')
    message = {'Invalid segmentation model.'; ...
               'Please select a valid .mat model file, then try again.'};
    return
end

% -------------------------------------------------------------------------
% Load model
% -------------------------------------------------------------------------
try
    dlgHandle = msgbox('Loading the model, please wait...', 'Loading', 'help');

    % Memory check (Windows only)
    if ispc
        sysMem        = memory;
        modelFileInfo = dir(app.comet_handles.segmentationOptions.modelPath);
        if sysMem.MaxPossibleArrayBytes < modelFileInfo.bytes
            if ishandle(dlgHandle), close(dlgHandle); end
            message = {'Not enough memory to load the segmentation model.'};
            return
        end
    end

    data = load(app.comet_handles.segmentationOptions.modelPath);

    % Flexible network field detection — supports net, netFinal, netAvg
    if isfield(data, 'net')
        net = data.net;
    elseif isfield(data, 'netFinal')
        net = data.netFinal;
    elseif isfield(data, 'netAvg')
        net = data.netAvg;
    else
        if ishandle(dlgHandle), close(dlgHandle); end
        message = {'No valid network found in model file.'; ...
                   'Expected field: net, netFinal, or netAvg.'};
        return
    end

    % Load metadata saved during training
    if ~isfield(data, 'classNames') || ~isfield(data, 'patchSize')
        if ishandle(dlgHandle), close(dlgHandle); end
        message = {'Model file is missing classNames or patchSize metadata.'; ...
                   'Please retrain using the current pipeline.'};
        return
    end

    classNames = data.classNames;
    patchSize  = data.patchSize;

catch me
    if ishandle(dlgHandle), close(dlgHandle); end
    message = {me.message; ''; ...
               'Please select a valid model in Segmentation Options.'};
    return
end

if ishandle(dlgHandle), close(dlgHandle); end

% -------------------------------------------------------------------------
% Detect execution environment
% -------------------------------------------------------------------------
useGPU = false;
env = app.comet_handles.segmentationOptions.ExecutionEnvironment;
if strcmp(env, 'auto') || strcmp(env, 'gpu') || strcmp(env, 'multi-gpu')
    try
        g = gpuDevice;
        if g.DeviceSupported
            useGPU = true;
        end
    catch
        % No compatible GPU available — fall back to CPU silently
    end
end

% -------------------------------------------------------------------------
% Determine which images to segment
% -------------------------------------------------------------------------
idx = false(app.comet_handles.NumImages, 1);

if strcmp(method, 'single')
    i = app.comet_handles.IndImgShown;
    if ~any(app.comet_handles.Imgs_Stretched(:,:,2,i), 'all')
        idx(i) = true;
    end
elseif strcmp(method, 'multi')
    for j = 1:app.comet_handles.NumImages
        if ~any(app.comet_handles.Imgs_Stretched(:,:,2,j), 'all')
            idx(j) = true;
        end
    end
end

if ~any(idx)
    if strcmp(method, 'single')
        message = {'The current image already contains annotations.'; ...
                   'Automatic segmentation only runs on unannotated images.'};
    else
        message = {'No unannotated images found.'; ...
                   'Automatic segmentation only runs on images without existing annotation.'};
    end
    return
end

% -------------------------------------------------------------------------
% Build post-processing params from app settings
% -------------------------------------------------------------------------
postParams.minObjectSize          = app.comet_handles.segmentationOptions.minObjectSize;
postParams.closingRadius          = app.comet_handles.segmentationOptions.closingRadius;
postParams.CometThAddFactor       = app.comet_handles.CometThAddFactor;
postParams.CometDiskDilation      = app.comet_handles.CometSizeDiskDilation;
postParams.HeadThAddFactor        = app.comet_handles.HeadThAddFactor;
postParams.HeadDiskDilation       = app.comet_handles.HeadSizeDiskDilation;
postParams.flag_ThresholdMode     = app.comet_handles.flag_ThresholdMode;
postParams.flag_ThresholdHeadMode = app.comet_handles.flag_ThresholdHeadMode;

% -------------------------------------------------------------------------
% Segment images
% -------------------------------------------------------------------------
stride        = patchSize / 2;
idx2          = find(idx);
numIm2Segment = numel(idx2);
failedImages  = [];

wb = waitbar(0, 'Segmentation in progress. Please wait...');

for i = 1:numIm2Segment
    imgIdx = idx2(i);

    try
        % Load and normalize image to single [0,1]
        I = im2single(app.comet_handles.Imgs_Stretched(:,:,1,imgIdx));

        % U-Net sliding window prediction
        C = semanticsegPatch(I, net, classNames, patchSize, stride, useGPU);
        clear I

        % Convert categorical to uint8 class indices
        % Head=1, Tail=2, Background=3
        C8 = uint8(C);
        clear C

        % Original uint8 image for watershed and segmentComet/segmentHead
        Img = app.comet_handles.Imgs_Stretched(:,:,1,imgIdx);

        % Post-processing: cleanup + watershed + per-object segmentation
        [segmentedComet, segmentedHead] = postProcessSegmentation(C8, Img, postParams);
        clear C8

        % Write results to app
        app.comet_handles.Imgs_Stretched(:,:,2,imgIdx) = segmentedComet;
        app.comet_handles.Imgs_Stretched(:,:,3,imgIdx) = segmentedHead;

    catch
        failedImages(end+1) = imgIdx;
    end

    if ishandle(wb)
        waitbar(i/numIm2Segment, wb, ...
            sprintf('Segmentation in progress. Please wait...\n%d / %d', ...
                    i, numIm2Segment));
    end
end

if ishandle(wb), close(wb); end

message = {'Segmentation complete.'; ''; ...
           [num2str(numIm2Segment), ' image(s) processed.']};
if ~isempty(failedImages)
    failedList   = strjoin(arrayfun(@num2str, failedImages, 'UniformOutput', false), ', ');
    message{end+1} = '';
    message{end+1} = ['WARNING: ' num2str(numel(failedImages)) ' image(s) failed (index): ' failedList];
end
bool = 1;
end