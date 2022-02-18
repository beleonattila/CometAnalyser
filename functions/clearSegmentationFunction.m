function clearSegmentationFunction(app)
% AUTHOR: Attila Beleon (E-mail: beleonattila@gmail.com)
% DATE: April 26, 2021
% Updated: February 18, 2022
% NAME: clearSegmentationFunction (version 1.0)
%
% Clearing masks created by automatic segmentation.
%
% INPUT:
%   app                 Handles of the application.
%
% OUTPUT:
%   This function modifies the app.comet_handles.Imgs_Streched by removing
%   masks with the ID = 255, from channel 2 and 3. (green and pink)
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

for i = 1:app.comet_handles.NumImages
    if any(app.comet_handles.Imgs_Stretched(:,:,2,i) == 255,'all')

    end
end