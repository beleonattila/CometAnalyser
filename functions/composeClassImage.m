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


cols = 4;
margin = 0.05 * axesWidth;
sepsize = 0.05 * axesWidth; %Distance Between thumbnails
classNames = fieldnames(Classes);
classNames = setdiff(classNames,'Unclassified');
imSize = ceil(((axesWidth - (2*margin)) - ((cols-1)*sepsize))/cols); % Catalog image size
backGround = 240;

for cl = 1:numel(classNames)
    
    numimgs = Classes.(classNames{cl}).num_el;
    rows = ceil(numimgs / cols);
    height = (rows * imSize) + ((rows+1) * sepsize);
    compImgs = uint8(zeros(height,axesWidth, 2));
    compImgs(:,:,1) = (compImgs(:,:,1)+1)*backGround;
    
    mapping = {};
    x = 1;
    y = 1;
    for i = 1:numimgs
        coor = Classes.(classNames{cl}).Members(i).thumbnailCoor;
        imID = Classes.(classNames{cl}).Members(i).ImID;
        
        if abs(coor(1,1)-coor(2,1)) >= abs(coor(2,2)-coor(1,2))
            imScaler = [imSize, NaN];
        else
            imScaler = [NaN, imSize];
        end
        
        resImg = imresize(imgs(coor(1,1):coor(2,1), coor(2,2):coor(1,2),1,imID), imScaler);
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
            compImgs(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1,1) = paddedImage(1:imSize,1:imSize);
            compImgs(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1,2) = i;
        else
            compImgs(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1,1) = resImg;
            compImgs(offseth:offseth+imSize-1,offsetw:offsetw+imSize-1,2) = i;
        end
        subimgmeta.CellNumber = i;
        subimgmeta.ImName = Classes.(classNames{cl}).Members(i).ImName;
        %         subimgmeta.OriginalImageName = classImg.OriginalImageName;
        mapping{y,x} = subimgmeta;
        x = x + 1;
    end
    classCatalog{cl,1} = classNames{cl};
    classCatalog{cl,2} = compImgs;
    classCatalog{cl,3} = mapping;
end
end