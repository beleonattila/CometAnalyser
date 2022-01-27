function classCatalog = composeClassImage(Classes, imgs, axesWidth)
% AUTHOR:	Attila Beleon
% DATE: 	Augustus 27, 2020
% NAME: 	composeClassCatalog
%
% To create the table-like image containing the thumbnails of a class of
% annotated comets.
%
% INPUT:
%   Classes         Class structure, contains member informations and
%                   coordinates
%
%   imgs            Cut out thumbnails from these images
%
% OUTPUT:
%   classCatalog    n-by-3 cell array, contains classNames, catalogImages
%                   and layout of comet properties.
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

cols = 4;
margin = 0.05 * axesWidth;
sepsize = 0.05 * axesWidth; %Distance Between thumbnails
classNames = fieldnames(Classes);
imSize = ceil(((axesWidth - (2*margin)) - ((cols-1)*sepsize))/cols); % Catalog image size
backGround = 240;
classCatalog = cell(numel(classNames),4);
for cl = 1:numel(classNames)
    
    numimgs = size(Classes.(classNames{cl}).Members,2);
    rows = ceil(numimgs / cols);
    height = (rows * imSize) + ((rows+1) * sepsize);
    mainIm = uint8(ones(height,axesWidth, 1)*backGround);
    idxIm = uint16(zeros(height,axesWidth, 1));
    
    mapping = cell(ceil(numimgs/cols),cols);
    x = 1;
    y = 1;
    for i = 1:numimgs
        cometID = Classes.(classNames{cl}).Members(i).cometID;
        imID = Classes.(classNames{cl}).Members(i).ImID;
        [xCoor,yCoor] = find(imgs(:,:,2,imID)==cometID);
        xMin = min(xCoor);
        xMax = max(xCoor);
        yMin = min(yCoor);
        yMax = max(yCoor);
        
        if xMax-xMin >= yMax-yMin
            imScaler = [imSize, NaN];
        else
            imScaler = [NaN, imSize];
        end
        
        resImg = imresize(imgs(xMin:xMax, yMin:yMax,1,imID), imScaler);
        if x > cols
            x = 1;
            y = y + 1;
        end
        [hight, width] = size(resImg);
        if hight ~= width
            padSize = abs((hight-width))/2;
            if hight>width
                resImg = [zeros(hight, floor(padSize)), resImg, zeros(hight, ceil(padSize))];
            else
                resImg = [zeros(floor(padSize), width); resImg; zeros(ceil(padSize), width)];
            end
        end
        offsetw = imSize * (x-1) + sepsize * x;
        offseth = imSize * (y-1) + sepsize * y;
        if size(resImg,1) ~= size(resImg,2)
            minSizeOfImg = min(size(resImg));
            padSize = ceil((imSize-minSizeOfImg)/2);
            padDirection = size(resImg)== minSizeOfImg;
            paddedImage = padarray(resImg,(padDirection*padSize), backGround);
            mainIm(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1) = paddedImage(1:imSize,1:imSize);
            idxIm(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1) = i;
        else
            mainIm(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1) = resImg;
            idxIm(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1) = i;
        end
        subimgmeta.CellNumber = i;
        subimgmeta.cometID = cometID;
        subimgmeta.ImName = Classes.(classNames{cl}).Members(i).ImName;
        mapping{y,x} = subimgmeta;
        x = x + 1;
    end
    classCatalog{cl,1} = classNames{cl};
    classCatalog{cl,2} = mainIm;
    classCatalog{cl,3} = mapping;
    classCatalog{cl,4} = idxIm;
end