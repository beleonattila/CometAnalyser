function exportAnnotation(app, path)

maskFolderName = 'Masks';
imagesFolderName = 'Images';

if ~isfolder(fullfile(path, maskFolderName))
    mkdir(fullfile(path, maskFolderName))
    mkdir(fullfile(path, imagesFolderName))
end
imNames = app.comet_handles.ImgsNames;
ids = find(any(any(app.comet_handles.Imgs_Composed(:,:,4,:))));
splitName = strsplit(imNames{ids(1)},'.');
inExt = splitName{end};
outExt = '.png';

for i = 1:length(ids)
    greyScale = app.comet_handles.Imgs_Stretched(:,:,1,ids(i));
    tail = app.comet_handles.Imgs_Composed(:,:,4,ids(i));
    head = app.comet_handles.Imgs_Composed(:,:,3,ids(i));
    head(~tail) = 0;
    head(head<255) = 0;
    tail = tail * 127;
    combined = tail + head;
    tempSplitName = strsplit(imNames{ids(i)},['.',inExt]);
    imwrite(combined,fullfile(path, maskFolderName,[tempSplitName{1},outExt]))
    imwrite(cat(3,greyScale,greyScale,greyScale),fullfile(path, imagesFolderName,[tempSplitName{1},outExt]))
end