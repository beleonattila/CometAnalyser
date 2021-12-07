function tempIm = classFilteredImage(im, cLabel, score, cnum, classNames, BB)

n = numel(classNames);
colorOrder = jet(n+2);
position = zeros(length(cnum),4);
imLabel = cell(length(cnum),1);
labelColor = zeros(length(cnum),3);
for i = 1:length(cnum)
   cBB = BB{i} + [-1 1; 1 -1];
   position(i,:) = [cBB(2,2) cBB(1,1) cBB(1,2)-cBB(2,2) cBB(2,1)-cBB(1,1)];
   imLabel{i} = [cLabel{i} '_|_' num2str(score(i,cnum(i)))];
   labelColor(i,:) = colorOrder(end - cnum(i),:)*255;
end

tempIm = insertObjectAnnotation(im,'rectangle',position,imLabel,'LineWidth',3,'Color',labelColor,'TextColor','black','FontSize',20);
