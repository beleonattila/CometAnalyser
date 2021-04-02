RGB = imread('D:\BRC\CometAnalyser\SampleImages\Fluorescence_dati01\sf.A549 sip53  6.tif');
imshow(RGB)

L = superpixels(RGB,15000);

% f = imfreehand(gca);

hf = drawfreehand;
% he = images.roi.Circle(...
%     'Center', [50 50],...
%     'Radius', 10,...
%     'Parent', gca,...
%     'Color','r');
% addlistener(he,'MovingROI', @(varargin)editorROIMoving(he, hf));
% addlistener(he,'ROIMoved', @(varargin)editFreehand(hf, he));
% f = drawrectangle(gca,'Position',[100 128 350 150],'Color','g');

foreground = createMask(hf,RGB) + createMask(hf2,RGB) + createMask(hf3,RGB) + createMask(hf4,RGB) + createMask(hf5,RGB);

b1 = drawrectangle(gca,'Position',[130 30 40 30],'Color','r');
b2 = drawrectangle(gca,'Position',[6 368 500 10],'Color','r');

background = createMask(b1,RGB) + createMask(b2,RGB) + createMask(b3,RGB) + createMask(b4,RGB);

BW = lazysnapping(RGB,L,foreground,background,'EdgeWeightScaleFactor',10);

imshow(labeloverlay(RGB,BW,'Colormap',[1 0 0]))

maskedImage = RGB;
maskedImage(repmat(~BW,[1 1 3])) = 0;
imshow(maskedImage*2)