function data = augmentImageAndLabel(data, xTrans, yTrans, rotVector, scaleVector)
% TODO comment and header
% Augment images and pixel label images using random reflection and
% translation.

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



for i = 1:size(data,1)
    
    tform = randomAffine2d(...
        'XReflection',true,...
        'YReflection',true,...
        'XTranslation', xTrans, ...
        'YTranslation', yTrans,...
        'Rotation',rotVector,...
        'Scale',scaleVector);
    
    % Center the view at the center of image in the output space while
    % allowing translation to move the output image out of view.
    rout = affineOutputView(size(data{i,1}), tform, 'BoundsStyle', 'centerOutput');
    
    % Warp the image and pixel labels using the same transform.
    data{i,1} = imwarp(data{i,1}, tform, 'OutputView', rout);
    data{i,2} = imwarp(data{i,2}, tform, 'OutputView', rout);
    
end