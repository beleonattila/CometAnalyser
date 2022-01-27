function composedImage = composeImage(im)
% TODO header and comments

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


intensityDownScale = 0.5;

ch1 = im(:,:,1);
ch2 = im(:,:,1);
ch3 = im(:,:,1);

% Down scale of intensity at the comet regions to increase the intensity of
% RED and BLUE colours and avoid white
ch1(logical(im(:,:,2))) = ch1(logical(im(:,:,2))) * intensityDownScale;
ch2(logical(im(:,:,2))) = ch2(logical(im(:,:,2))) * intensityDownScale;
ch3(logical(im(:,:,2))) = ch3(logical(im(:,:,2))) * intensityDownScale;

% tailLayer = logical(im(:,:,2)) - logical(im(:,:,3));

Red_tailLayer = im(:,:,2)>0 & im(:,:,2)<255;
Red_tailLayer(logical(im(:,:,3))) = 0;

Green_tailLayer = im(:,:,2)>254;
Green_tailLayer(logical(im(:,:,3))) = 0;

Blue_headLayer = im(:,:,3)>0 & im(:,:,3)<255;

Magenta_headLayer = im(:,:,3)>254;

% Make the tail red
ch1(Red_tailLayer) = 255;

% Make the head blue
ch3(Blue_headLayer) = 255;

% Make the tail green
ch2(Green_tailLayer) = 255;

% Make the tail magenta
ch1(Magenta_headLayer) = 255;
ch3(Magenta_headLayer) = 255;

composedImage = cat(3,ch1,ch2,ch3);