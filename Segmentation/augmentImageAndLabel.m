function data = augmentImageAndLabel(data, xTrans, yTrans, rotVector, scaleVector, intensityThreshold)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 2, 2021
% Updated: February 18, 2022
% NAME: augmentImageAndLabel (version 1.0)
%
% Augment images and pixel label images using random reflection,
% translation, rotation, resize and noise.
%
% INPUT:
% 	data                Original data for segmentation
%   xTrans              Transition value for X direction
%   yTrans              Transition value for Y direction
%   rotVector           Rotation angle
%   scaleVector         Vector with min and max values of scaling values
%   intensityThreshold  Vector with min and max values of random intensity
%                       scaling
%
%
% OUTPUT:
%   data                Augmented data
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
    
    % random noise
    k = randi(10);
    if k > 1
        if k > 8
            J = imnoise(data{i,1}(:,:,1),'gaussian',0.001,0.005);
        elseif k < 4
            J = imnoise(data{i,1}(:,:,1),'poisson');
        else
            J = imnoise(data{i,1}(:,:,1),'speckle');
        end
        data{i,1} = cat(3,J,J,J);
    end
    
    % random intensity
    if randi([0 1])
        randScaler = intensityThreshold(1) + rand * range(intensityThreshold);
        data{i,1} = data{i,1}.*randScaler;
    elseif randi([0 1])
        medianInt = median(data{i,1},'all');
        randScaler = medianInt * (intensityThreshold(1) + rand * range(intensityThreshold));
        data{i,1} = data{i,1} + randScaler;
    end
    
end