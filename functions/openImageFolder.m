function bool = openImageFolder(app)

bool = 0;
if ishandle(app.comet_handles.h_GUIhelpA); close(app.comet_handles.h_GUIhelpA); end


app.scope.ImageSource = app.CometIcon;
app.selectedComet = [];

if app.comet_handles.LoadImagesOngoing == 1
    return
end

[ImageName, PathInputFolder] = uigetfile({'*.tif;*.tiff;*.bmp;*.png;*.jpg;'}, 'Select in the input folder one of the images to be processed', 'MultiSelect', 'off', app.comet_handles.PathInputFolderOriginal);
if ~isempty(PathInputFolder) && all(PathInputFolder~=0)
    app.comet_handles.LoadImagesOngoing = 1;
    if app.comet_handles.FluorescenceImages == 0
        errorString = {'Images will be displayed with black background.'};
        appTextDlg(app, errorString, 'Message', 'help')
    end
    
    try
        % Read Path, name, Format
        splitName = split(ImageName, '.');
        ImageFormat = splitName{end};
        
        % Check if the input images are gray-level 8-bit images
        dirList = dir([PathInputFolder, '*.' ImageFormat]);
        ImgsNames = {dirList(:).name}';
        NumImages = length(dirList(:));
        imInfo = imfinfo(fullfile(PathInputFolder, ImageName));
        Imgs_Ori = uint8(zeros(imInfo.Height, imInfo.Width, 1, NumImages));
        
        inputOptions={'Red','Green','Blue','Gray conversion'};
        defSelection=inputOptions{4};
        iSel=bttnChoiseDialog(inputOptions, 'Load images', defSelection,...
            'Which channel do you want load?');
        flag_channelToLoad = iSel;
        wb = waitbar(0,sprintf('Importing images. Please wait! \n %d / %d Images', 0, NumImages));
        for i=1:NumImages
            referenceFrame = imread(fullfile(PathInputFolder, dirList(i).name));
            [row, col, ch, t] = size(referenceFrame);
            if i>1 && (row_old ~= row || col_old ~= col || ch_old ~= ch || t_old ~= t)
                errorString = {['All the input images must be of the same size.';'';'Image: "' char(dirList(i).name) '" is of a different size.']};
                appTextDlg(app, errorString, 'Error', 'error')
                if ishandle(wb), close(wb), end
                return
            end

            if i==1 && ~isa(referenceFrame, 'uint8')
                errorString = {'The input images must be gray-level 8-bit images.';'';'The images have been converted accordingly.'};
                appTextDlg(app, errorString, 'Message', 'help')
            end
            
            if size(referenceFrame, 3)~=1
                if flag_channelToLoad == 1 || flag_channelToLoad == 2 || flag_channelToLoad == 3
                    referenceFrame = referenceFrame(:,:,flag_channelToLoad);
                elseif flag_channelToLoad == 4
                    referenceFrame = rgb2gray(referenceFrame);
                else
                    errorString = {'Incorrect selection.'};
                    appTextDlg(app, errorString, 'Error', 'error')
                end
            end

            Imgs_Ori(:,:,1,i) = uint8(referenceFrame);
            clear referenceFrame
            row_old = row; col_old = col; ch_old = ch; t_old = t;
            if ishandle(wb)
                waitbar(i/NumImages,wb,sprintf('Importing images. Please wait! \n %d / %d Images', i, NumImages));
            else
                wb = waitbar(i,sprintf('Importing images. Please wait! \n %d / %d Images', i, NumImages));
            end
        end
        if ishandle(wb), close(wb), end
        
        % Compute MinValue and MaxValue
        MinValue = min(Imgs_Ori,[],'all');
        MaxValue = max(Imgs_Ori,[],'all');
        
        % Update MinValue and MaxValue
        if MaxValue <= MinValue
            errorString = {'The minimum and the maximum values of the input images are coincident.'};
            appTextDlg(app, errorString, 'Error', 'error')
            return
        end
        
        % Check for seeing if the user click on the correct load button
        flagEstimated_FluorescenceImages = checkFluorescentImages(Imgs_Ori(:,:,1,i));
        if flagEstimated_FluorescenceImages ~= app.comet_handles.FluorescenceImages
            % Construct a questdlg with two options
            if app.comet_handles.FluorescenceImages==1
                choice = questdlg('Are you sure that you loaded fluorescent images?', ...
                    'Check input images', ...
                    'Yes','No','Yes');
            else
                choice = questdlg('Are you sure that you loaded non-fluorescent images?', ...
                    'Check input images', ...
                    'Yes','No','Yes');
            end
            % Handle response
            switch choice
                case 'Yes'
                otherwise
                    errorString = {'Please, re-load the images using the correct button.'};
                    appTextDlg(app, errorString, 'Error', 'error')
                    clear Imgs_Ori MinValue MaxValue referenceFrame ImageName PathInputFolder dirList
                    app.comet_handles.LoadImagesOngoing = 0;
                    app.comet_handles.FluorescenceImages = 0;
                    return
            end
        end
        
        % To leave for masks saving purposes the value 255
        a = double(0);   %Theoretically->double(0);
        b = double(255); %Theoretically->double(255);
        % Save the images
        c = double(MinValue); % Original Intesity values
        d = double(MaxValue); % Original Intesity values
        
        % Modify the original images by stretching
        Imgs_Stretched = Imgs_Ori;
        Imgs_Stretched(Imgs_Stretched>MaxValue) = MaxValue;
        Imgs_Stretched(Imgs_Stretched<MinValue) = MinValue;
        Imgs_Stretched = ((Imgs_Stretched-c).*((b-a)/(d-c)))+a;
        if app.comet_handles.FluorescenceImages == 0
            Imgs_Stretched = imcomplement(Imgs_Stretched);
            Imgs_Ori = imcomplement(Imgs_Ori);
        end
        
        Imgs_Stretched(:,:,2:3,:) = 0;
        
        % Save parameters
        app.comet_handles.IntensityMinValStretched = a;
        app.comet_handles.IntensityMaxValStretched = b;
        app.comet_handles.IntensityMinValOrig = c;
        app.comet_handles.IntensityMaxValOrig = d;
        app.comet_handles.Imgs_Stretched = Imgs_Stretched;
        app.comet_handles.Imgs_Ori = Imgs_Ori;
        app.comet_handles.NumImages = NumImages;
        app.comet_handles.ImageFormat = ImageFormat;
        [imHigh, imWidth, ~, ~] = size(Imgs_Stretched);
        app.comet_handles.ImageSize = [imHigh, imWidth];
        app.comet_handles.dirList = dirList;
        app.comet_handles.ImgsNames = ImgsNames;
        app.comet_handles.IndImgShown = 1;
        app.comet_handles.PathInputFolderOriginal = PathInputFolder;
        app.comet_handles.LoadImagesOngoing = 0;
        set(app.text_Num,'Text', ['Image: ' '1' '/' num2str(NumImages)]);
        set(app.text_Name,'Text', ['Image: ' char(app.comet_handles.dirList(ceil(1)).name)]);
        imshow(composeImage(app.comet_handles.Imgs_Stretched(:,:,:,app.comet_handles.IndImgShown)), [], 'Parent', app.axes1);
        app.axes1.XAxis.Visible = 'off';
        app.axes1.YAxis.Visible = 'off';
        app.axes1.XTickLabel = [];
        app.axes1.YTickLabel = [];
        app.axes1.BackgroundColor = [0 0 0];
        app.axes1.Toolbar.Visible = "off";
        app.axes1.XLim = [0, app.comet_handles.ImageSize(2)];
        app.axes1.YLim = [0, app.comet_handles.ImageSize(1)];
        pause(.1)
        drawnow
        pause(.1)
        bool = 1;
        
    catch
        if exist("PathInputFolder", 'var') && exist("dirList", 'var') && exist("NumImages", 'var')
            for i=1:NumImages
                info = imfinfo(fullfile(PathInputFolder, dirList(i).name));
                if size(info,1) ~= 1
                    errorString = {["Please, select a compatible image.";"";"";...
                        "The input image:";"";"";...
                        fullfile(PathInputFolder, dirList(i).name);...
                        "is a multi layer image. Please use single layer images."]};
                    break
                else
                    errorString = {["Something went wrong.";"";"";...
                        "Please contact the developeres:";"";"";...
                        "beleonattila@gmail.com";...
                        "filippo.piccinini85@gmail.com"]};
                end
            end
        else
            errorString = {["Please, select a compatible image.";"";"";...
                "The input folder must contain only images and no other files.";"";"";...
                "The basename of the images cannot contain spaces and special characters, and must be in the format: ""BasenameImage_###.ImageFormat""."]};
        end
        appTextDlg(app, errorString, 'Error', 'error')
        app.comet_handles.LoadImagesOngoing = 0;
        app.comet_handles.FluorescenceImages = 0;
    end
    
else
    app.comet_handles.FluorescenceImages = 0;
end
