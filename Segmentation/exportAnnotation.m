function [bool, message] = exportAnnotation(app, path)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 2, 2021
% Updated: May 6, 2026
% NAME: exportAnnotation (version 2.0)
%
% Exports all loaded images and their pixel-label masks to disk.
% Images are saved as single-precision TIFF in [0,1] range.
% Masks are saved as uint8 PNG with label values 0 (Background),
% 127 (Tail), 255 (Head).
%
% All images in the dataset are exported — unannotated images receive an
% all-zero (Background-only) mask. Run preprocessPatchDataset separately
% to extract training patches from the exported dataset.
%
% INPUT:
% 	app                 Handles of the APP
%   path                Selected path to save images
%
% OUTPUT:
%   bool                1 on success, 0 on failure
%   message             Error message cell array if failed, empty otherwise
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
message = [];

maskFolderName = 'Masks';
imagesFolderName = 'Images';

if exist(fullfile(path, maskFolderName),"dir")
    answer = questdlg('The selected folder is not empty. Would you like to continue?','Not empty folder','Continue','Cancel','Cancel');
    if strcmp(answer,'Continue')
        mkdir(fullfile(path, maskFolderName))
        mkdir(fullfile(path, imagesFolderName))
    else
        message = {'Process terminated.'};
        return
    end
else
    mkdir(fullfile(path, maskFolderName))
    mkdir(fullfile(path, imagesFolderName))
end

imNames = app.comet_handles.ImgsNames;
nImages = numel(imNames);

hasAnyAnnotation = any(any(any(app.comet_handles.Imgs_Stretched(:,:,2,:)))) || ...
                   any(any(any(app.comet_handles.Imgs_Stretched(:,:,3,:))));
if ~hasAnyAnnotation
    message = {'There are no annotations in this dataset.'};
    return
end

splitName = strsplit(imNames{1}, '.');
inExt = splitName{end};
wb = waitbar(0, 'Saving annotation. Please wait...');

for i = 1:nImages
    tail = app.comet_handles.Imgs_Stretched(:,:,2,i);
    tail(tail>0) = 127;
    head = app.comet_handles.Imgs_Stretched(:,:,3,i);
    head(head>0) = 255;
    combined = uint8(tail + head);

    tempSplitName = strsplit(imNames{i}, ['.', inExt]);
    baseName = tempSplitName{1};

    % Mask — uint8 PNG (0=Background, 127=Tail, 255=Head)
    imwrite(combined, fullfile(path, maskFolderName, [baseName, '.png']))

    % Image — single-precision TIFF in [0,1] (required by preprocessPatchDataset)
    img = single(app.comet_handles.Imgs_Ori(:,:,1,i));
    if max(img(:)) > 1
        img = img / 255;
    end
    imgPath = fullfile(path, imagesFolderName, [baseName, '.tif']);
    t = Tiff(imgPath, 'w');
    t.setTag('Photometric',         Tiff.Photometric.MinIsBlack);
    t.setTag('ImageLength',         size(img, 1));
    t.setTag('ImageWidth',          size(img, 2));
    t.setTag('BitsPerSample',       32);
    t.setTag('SampleFormat',        Tiff.SampleFormat.IEEEFP);
    t.setTag('SamplesPerPixel',     1);
    t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
    t.write(img);
    t.close();

    if ishandle(wb)
        waitbar(i/nImages, wb, sprintf('%d / %d Saving. Please wait...', i, nImages))
    end
end

bool = 1;
if ishandle(wb)
    close(wb)
end
helpdlg('Exportation accomplished!')