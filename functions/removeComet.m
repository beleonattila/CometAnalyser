function removeComet(app)
if ~isempty(app.comet_handles.NumImages)
    if ~isempty(app.selectedComet)
        
        coor = app.selectedComet.param.thumbnailCoor;
        mask = app.selectedComet.param.mask;
        ImID = app.selectedComet.param.ImID;
        ROI = app.comet_handles.Imgs_Composed(coor(1,1):coor(2,1), coor(2,2):coor(1,2), 4, ImID);
        ROI(logical(mask)) = 0;
        app.comet_handles.Imgs_Composed(coor(1,1):coor(2,1), coor(2,2):coor(1,2), 4, ImID) = ROI;
        
        ROIorig = app.comet_handles.Imgs_Stretched(coor(1,1):coor(2,1), coor(2,2):coor(1,2), 1, ImID);
        app.comet_handles.Imgs_Composed(coor(1,1):coor(2,1), coor(2,2):coor(1,2), 1, ImID) = ROIorig;
        app.comet_handles.Imgs_Composed(coor(1,1):coor(2,1), coor(2,2):coor(1,2), 2, ImID) = ROIorig;
        app.comet_handles.Imgs_Composed(coor(1,1):coor(2,1), coor(2,2):coor(1,2), 3, ImID) = ROIorig;
        
        
        numOfMembers = app.comet_handles.Classes.(app.selectedComet.className).num_el;
        if numOfMembers <= 1
            app.comet_handles.Classes.(app.selectedComet.className).Members.ImName = [];
            app.comet_handles.Classes.(app.selectedComet.className).Members.ImID = [];
            app.comet_handles.Classes.(app.selectedComet.className).Members.mask = [];
            app.comet_handles.Classes.(app.selectedComet.className).Members.thumbnailCoor = [];
            app.comet_handles.Classes.(app.selectedComet.className).num_el = 0;
        else
            maskCenterPoint = round([(coor(2, 1) + coor(1, 1))/2, (coor(2, 2) + coor(1, 2))/2]);
            for z = 1:numOfMembers
                memberCoor = app.comet_handles.Classes.(app.selectedComet.className).Members(z).thumbnailCoor;
                if maskCenterPoint(1) > memberCoor(1, 1) && maskCenterPoint(1) < memberCoor(2, 1) && ...
                        maskCenterPoint(2) > memberCoor(2, 2) && maskCenterPoint(2) < memberCoor(1, 2)
                    memberIdx = z;
                    break
                end
            end
            app.comet_handles.Classes.(app.selectedComet.className).Members(memberIdx)= [];
            app.comet_handles.Classes.(app.selectedComet.className).num_el = app.comet_handles.Classes.(app.selectedComet.className).num_el - 1;
        end
        app.scope.ImageSource = app.CometIcon;
    else
        errorString = 'The selected comet has invalid classID that greater than the number of classes!';
        appTextDlg(app, errorString, 'Corrupted class container', 'error')
    end
    
    imshow(uint8(app.comet_handles.Imgs_Composed(:, :, 1:3, app.comet_handles.IndImgShown)), [], 'Parent', app.axes1);
    
    % Reset the ROI
    
    app.comet_handles.ROIshown = 0;
    app.comet_handles.ROIori = [];
    app.comet_handles.ROIoriFiltered = [];
    app.comet_handles.ROIsegm = [];
    app.comet_handles.MaskComet = [];
    app.comet_handles.MaskHead = [];
    app.comet_handles.ROI_ULCyx_DRCyx = [];
end
end