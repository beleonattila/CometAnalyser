function [bool, message] = exportAnnotation(app, path)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 2, 2021
% Updated: February 18, 2022
% NAME: exportAnnotation (version 1.0)
%
% Exporting images and masks.
%
% INPUT:
% 	app                 Handles of the APP
%   path                Selected path to save images
%
%
% OUTPUT:
%   bool                Succssor
%   message             Error message if something goes wrong
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

if ~isfolder(fullfile(path, maskFolderName))
    mkdir(fullfile(path, maskFolderName))
    mkdir(fullfile(path, imagesFolderName))
end
imNames = app.comet_handles.ImgsNames;
ids = find(any(any(app.comet_handles.Imgs_Stretched(:,:,2,:))));
if ~isempty(ids)
    
    splitName = strsplit(imNames{ids(1)},'.');
    inExt = splitName{end};
    outExt = '.png';
    wb = waitbar(0,'Saving annotation. Please wait...');
    n = length(ids);
    for i = 1:n
        greyScale = app.comet_handles.Imgs_Ori(:,:,1,ids(i));
        tail = app.comet_handles.Imgs_Stretched(:,:,2,ids(i));
        tail(tail>0) = 127;
        
        head = app.comet_handles.Imgs_Stretched(:,:,3,ids(i));
        head(head>0) = 255;
        
        combined = tail + head;
        tempSplitName = strsplit(imNames{ids(i)},['.',inExt]);
        imwrite(combined,fullfile(path, maskFolderName,[tempSplitName{1},outExt]))
        imwrite(cat(3,greyScale,greyScale,greyScale),fullfile(path, imagesFolderName,[tempSplitName{1},outExt]))
        if ishandle(wb)
            waitbar(i/n,wb,sprintf('%d / %d Saving annotation. Please wait...',i,n))
        end
    end
    bool = 1;
    if ishandle(wb)
        close(wb)
    end
    helpdlg('Exportation accomplished!')
else
    message = {'There are no annotations in this dataset.'};
end