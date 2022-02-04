function Imgs_Stretched = oldComposed2NewStretched(Imgs_Composed)
% Converting the old Composed to new Stretched version and removing the
% small high intensity dots that considered noise.

Imgs_Stretched = Imgs_Composed(:,:,2,:);

cometHeads = Imgs_Composed(:,:,3,:);
cometHeads(cometHeads<255) = 0;
cometHeads2 = bwareaopen(logical(cometHeads), 10);
Imgs_Stretched(:,:,3,:) = cometHeads2*255;

cometMasks = Imgs_Composed(:,:,1,:);
cometMasks(cometMasks<255) = 0;
cometMasks2 = bwareaopen(logical(cometMasks), 10);
Imgs_Stretched(:,:,2,:) = cometMasks2*255;
Imgs_Stretched(:,:,2,:) = Imgs_Stretched(:,:,2,:) + Imgs_Stretched(:,:,3,:);