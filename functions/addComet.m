function warnString = addComet(app)
warnString = [];
if ~isempty(app.comet_handles.NumImages)
    if strcmp(app.pop_class.Value,'~No Class~')
        warnString = 'Create a class first!';
        return
%     elseif ~isempty(app.selectedComet)
%         warnString = 'This comet is classified already!';
%         return
    end
    
    if app.comet_handles.ROIshown == 1
        
        ROIori = app.comet_handles.ROIori;
        if all(ROIori(:)==0) || all(ROIori(:)==255)
            app.comet_handles.ROIshown = 0;
            app.comet_handles.ROIori = [];
            app.comet_handles.ROIoriFiltered = [];
            app.comet_handles.ROIsegm = [];
            app.comet_handles.MaskComet = [];
            app.comet_handles.MaskHead = [];
            app.comet_handles.ROI_ULCyx_DRCyx = [];
            if exist('hFigFree2', 'var'); delete(hFigFree2); end
            warnString = 'No comet has been detected.';
            return
        end
        
        MaskHead = app.comet_handles.MaskHead;
        MaskComet = app.comet_handles.MaskComet;
        flag_CurrentCometType = app.comet_handles.flag_CurrentCometType;
        ROI_ULCyx_DRCyx = app.comet_handles.ROI_ULCyx_DRCyx;
        ULC_Yrow_roi = ROI_ULCyx_DRCyx(1,1); ULC_Xcol_roi = ROI_ULCyx_DRCyx(1,2); DRC_Yrow_roi = ROI_ULCyx_DRCyx(1,3); DRC_Xcol_roi = ROI_ULCyx_DRCyx(1,4);
        IndImgShown = app.comet_handles.IndImgShown;
        Imgs_Composed = app.comet_handles.Imgs_Composed;
        
        
        % To delete external pixels in case of perfect fit.
        flag_CometFitFreehand = app.comet_handles.flag_CometFitFreehand;
        ROIsegm = app.comet_handles.ROIsegm;
        if flag_CometFitFreehand == 1
            if ~isempty(MaskHead)
                MaskHead(ROIsegm==0)=0;
            end
            if ~isempty(MaskComet)
                MaskComet(ROIsegm==0)=0;
            end
        end
        
        ROIcomposed = falseColorsComet(ROIori, MaskHead, MaskComet, flag_CurrentCometType);
        
        app.scope.ImageSource = uint8(ROIcomposed);
        
        
        [rowI, colI, ~, ~] = size(Imgs_Composed);
        ImgComposedCh1 = Imgs_Composed(:, :, 1, IndImgShown);
        ImgComposedCh2 = Imgs_Composed(:, :, 2, IndImgShown);
        ImgComposedCh3 = Imgs_Composed(:, :, 3, IndImgShown);
        ImgComposedCh4 = Imgs_Composed(:, :, 4, IndImgShown);
        ImgMaskInd = zeros(rowI, colI);
        ImgROIcomposedCh1 = zeros(rowI, colI);
        ImgROIcomposedCh2 = zeros(rowI, colI);
        ImgROIcomposedCh3 = zeros(rowI, colI);
        ImgROIcomposedCh1(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = ROIcomposed(:,:,1);
        ImgROIcomposedCh2(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = ROIcomposed(:,:,2);
        ImgROIcomposedCh3(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = ROIcomposed(:,:,3);
        ImgMaskInd(ULC_Yrow_roi:DRC_Yrow_roi, ULC_Xcol_roi:DRC_Xcol_roi) = MaskComet;
        Inds = find(ImgMaskInd==1);
        
        if isempty(Inds)
            % Reset the ROI
            
            app.scope.ImageSource = app.CometIcon;
            app.selectedComet = [];
            app.comet_handles.ROIshown = 0;
            app.comet_handles.ROIori = [];
            app.comet_handles.ROIoriFiltered = [];
            app.comet_handles.ROIsegm = [];
            app.comet_handles.MaskComet = [];
            app.comet_handles.MaskHead = [];
            app.comet_handles.ROI_ULCyx_DRCyx = [];
            if exist('hFigFree2', 'var'); delete(hFigFree2); end
            warnString = 'No comet has been selected.';
%             appTextDlg(app, errorString, 'Message', 'warn')
            return
        end
        
        % Dilate the image of one pixel to be sure that the new comet is not
        % touching and not overlapping to others.
        ImgMaskInd_Dil = imdilate(ImgMaskInd, ones(3,3));
        Inds_Dil = find(ImgMaskInd_Dil==1);
        
        %Check if other masks are already there
        if isempty(app.selectedComet)
            if max(ImgComposedCh1(Inds_Dil)-ImgComposedCh2(Inds_Dil))>0 || max(ImgComposedCh3(Inds_Dil)-ImgComposedCh2(Inds_Dil))>0
                
                app.scope.ImageSource = app.CometIcon;
                app.selectedComet = [];
                app.comet_handles.ROIshown = 0;
                app.comet_handles.ROIori = [];
                app.comet_handles.ROIoriFiltered = [];
                app.comet_handles.ROIsegm = [];
                app.comet_handles.MaskComet = [];
                app.comet_handles.MaskHead = [];
                app.comet_handles.ROI_ULCyx_DRCyx = [];
                if exist('hFigFree2', 'var'); delete(hFigFree2); end
                warnString = ['Two comets overlap or touch: it is not possible to save overlapping or touching comets.' ...
                    '\n Modify the segmentation parameters or remove the other previously segmented comet!'];
                return
            end
        else
            mask = app.selectedComet.param.mask;
            BB = app.selectedComet.param.thumbnailCoor;
            prevFilter = zeros(rowI, colI);
            prevFilter(BB(1,1):BB(2,1),BB(2,2):BB(1,2)) = mask;
            prevFilter = logical(prevFilter);
            Imgs_Stretched = app.comet_handles.Imgs_Stretched(:,:,1,IndImgShown);
            ImgComposedCh1(prevFilter) = Imgs_Stretched(prevFilter);
            ImgComposedCh2(prevFilter) = Imgs_Stretched(prevFilter);
            ImgComposedCh3(prevFilter) = Imgs_Stretched(prevFilter);
            ImgComposedCh4(prevFilter) = 0;
        end
        
        ClassID = app.comet_handles.ClassID;
        
        ImgComposedCh1(Inds) = ImgROIcomposedCh1(Inds);
        ImgComposedCh2(Inds) = ImgROIcomposedCh2(Inds);
        ImgComposedCh3(Inds) = ImgROIcomposedCh3(Inds);
        ImgComposedCh4(Inds) = ClassID;
        Imgs_Composed(:, :, 1, IndImgShown) = ImgComposedCh1;
        Imgs_Composed(:, :, 2, IndImgShown) = ImgComposedCh2;
        Imgs_Composed(:, :, 3, IndImgShown) = ImgComposedCh3;
        Imgs_Composed(:, :, 4, IndImgShown) = ImgComposedCh4;
        imshow(uint8(Imgs_Composed(:,:,1:3,IndImgShown)), [], 'Parent', app.axes1);
        
        [maskRow, maskCol] = find(ImgMaskInd_Dil==1);
        
        thumbnailCoor = [min(maskRow), max(maskCol);...
                         max(maskRow), min(maskCol)];
        className = app.pop_class.Value;
        coor = [round((BB(2,2)+BB(1,2))/2), round((BB(1,1)+BB(2,1))/2)];
        classIdx = app.comet_handles.Imgs_Composed(coor(2),coor(1),4,app.comet_handles.IndImgShown);
        if isempty(app.selectedComet) || classIdx == 255
            if app.comet_handles.Classes.(className).num_el < 1
                app.comet_handles.Classes.(className).Members.ImName = app.comet_handles.ImgsNames{IndImgShown};
                app.comet_handles.Classes.(className).Members.ImID = IndImgShown;
                app.comet_handles.Classes.(className).Members.thumbnailCoor = thumbnailCoor;
                app.comet_handles.Classes.(className).Members.mask = ImgMaskInd(thumbnailCoor(1,1):thumbnailCoor(2,1),thumbnailCoor(2,2):thumbnailCoor(1,2));
                app.comet_handles.Classes.(className).num_el = 1;
            else
                numOfElements = app.comet_handles.Classes.(className).num_el;
                app.comet_handles.Classes.(className).Members(numOfElements+1).ImName = app.comet_handles.ImgsNames{IndImgShown};
                app.comet_handles.Classes.(className).Members(numOfElements+1).ImID = IndImgShown;
                app.comet_handles.Classes.(className).Members(numOfElements+1).thumbnailCoor = thumbnailCoor;
                app.comet_handles.Classes.(className).Members(numOfElements+1).mask = ImgMaskInd(thumbnailCoor(1,1):thumbnailCoor(2,1),thumbnailCoor(2,2):thumbnailCoor(1,2));
                app.comet_handles.Classes.(className).num_el = app.comet_handles.Classes.(className).num_el + 1;
            end
        else
            classNames = fieldnames(app.comet_handles.Classes);
            membersOnThisImage = app.comet_handles.Classes.(classNames{classIdx}).Members([app.comet_handles.Classes.(classNames{classIdx}).Members.ImID] == IndImgShown);
            CometID = [];
            for thumbIterator = 1:size(membersOnThisImage,2)
                currentThumbcoor = membersOnThisImage(thumbIterator).thumbnailCoor;
                if currentThumbcoor(1, 1) < coor(2) && currentThumbcoor(2, 1) > coor(2) &&...
                        currentThumbcoor(2, 2) < coor(1) && currentThumbcoor(1, 2) > coor(1)
                    if isempty(CometID)
                        CometID = thumbIterator;
                    else
                        warnString = ['Selected coordinates have been found stored as coordinates of multipe class members!\n' ...
                            '  Please contact the developer!'];
                        app.calculating = 0;
                        return
                    end
                end
            end
            if ~isempty(CometID)
                if isequal(app.selectedComet.param,app.comet_handles.Classes.(className).Members(CometID))
                    app.comet_handles.Classes.(className).Members(CometID).thumbnailCoor = thumbnailCoor;
                    app.comet_handles.Classes.(className).Members(CometID).mask = ImgMaskInd(thumbnailCoor(1,1):thumbnailCoor(2,1),thumbnailCoor(2,2):thumbnailCoor(1,2));
                else
                    warnString = ['Selected coordinates have been found stored as coordinates of multipe class members!\n' ...
                            '  Please contact the developer!'];
                end
            else
                warnString = ['Selected coordinates have been found stored as coordinates of multipe class members!\n' ...
                            '  Please contact the developer!'];
            end
        end
        
        app.comet_handles.Imgs_Composed = Imgs_Composed;
        app.comet_handles.FlagNewComets = app.comet_handles.FlagNewComets + 1;
        
        % Reset the ROI
        
        app.scope.ImageSource = app.CometIcon;
        app.selectedComet = [];
        app.comet_handles.ROIshown = 0;
        app.comet_handles.ROIori = [];
        app.comet_handles.ROIoriFiltered = [];
        app.comet_handles.ROIsegm = [];
        app.comet_handles.MaskComet = [];
        app.comet_handles.MaskHead = [];
        app.comet_handles.ROI_ULCyx_DRCyx = [];
        
    end
end
end