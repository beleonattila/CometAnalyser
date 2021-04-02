function predictImageSegmentation(app,method)

try
    net = load(app.comet_handles.segmentationOptions.modelPath);
catch me
    if strcmp(me.identifier,'MATLAB:load:couldNotReadFile')
        [fileName, path] = uigetfile('Select a pre-trained model!');
        if ischar(path)
            app.comet_handles.segmentationOptions.modelPath = fullfile(path,fileName);
            predictImageSegmentation(app,method)
            return
        end
    end
end

if strcmp(method, 'single')
    idx = app.comet_handles.IndImgShown;
elseif strcmp(method, 'multi')
    idx = app.comet_handles.NumImages;
end

for i = 1:length(idx)
    I = app.comet_handles.Imgs_Stretched(:,:,1,idx(i));
    I = cat(3,I,I,I);
    [C, ~, ~] = semanticseg(I, net.net);
    C8 = uint8(C);
    C8(C8 == 3) = 0;
    BW = imbinarize(C8);
    BW_fill = imfill(BW, 'holes');
    BW2 = bwareaopen(BW_fill,250);
    C8(~BW2) = 0;
    green = C8;
    green(BW2 & C8 == 2) = 255;
    magenta = C8;
    magenta(C8 == 1) = 255;
    
    app.comet_handles.Imgs_Composed(:,:,2,idx(i)) = app.comet_handles.Imgs_Composed(:,:,2,idx(i)) + green;
    app.comet_handles.Imgs_Composed(:,:,1,idx(i)) = app.comet_handles.Imgs_Composed(:,:,1,idx(i)) + magenta;
    app.comet_handles.Imgs_Composed(:,:,3,idx(i)) = app.comet_handles.Imgs_Composed(:,:,3,idx(i)) + magenta;
    app.comet_handles.Imgs_Composed(:,:,4,idx(i)) = app.comet_handles.Imgs_Composed(:,:,4,idx(i)) + magenta + green;
end