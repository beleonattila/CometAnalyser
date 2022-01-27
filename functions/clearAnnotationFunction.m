function clearAnnotationFunction(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% NAME: predictImageSegmentation (version 1.0)
%
% Performing automatic segmentation by the selected pretrained network.
%
% INPUT:
%   app                 Handles of the application.
%
% OUTPUT:
%   This function modifies the app.comet_handles.Imgs_Composed by removing
%   green and pink colour from channel 1, 2 and 3
%   Remove class label ID from Channel 4
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

imIdx = app.comet_handles.IndImgShown;
classNames = fieldnames(app.comet_handles.Classes);

for i = 1:numel(classNames)
    imNameIDX = [app.comet_handles.Classes.(classNames{i}).Members.ImID] == imIdx;
    app.comet_handles.Classes.(classNames{i}).Members(imNameIDX) = [];
end

app.comet_handles.Imgs_Stretched(:,:,2,imIdx) = 0;
app.comet_handles.Imgs_Stretched(:,:,3,imIdx) = 0;
