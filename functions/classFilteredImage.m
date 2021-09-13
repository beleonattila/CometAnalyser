function tempIm = classFilteredImage(im, out, props, classNames, BB)

n = numel(classNames);
colorOrder = jet(n+2);
position = zeros(length(out),4);
label = cell(length(out),1);
labelColor = zeros(length(out),3);
for i = 1:length(out)
   cBB = BB{i} + [-1 1; 1 -1];
   position(i,:) = [cBB(2,2) cBB(1,1) cBB(1,2)-cBB(2,2) cBB(2,1)-cBB(1,1)];
   label{i} = [num2str(out(i)) '_|_' num2str(props(i,out(i)))];
   labelColor(i,:) = colorOrder(end - out(i),:)*255;
end

tempIm = insertObjectAnnotation(im,'rectangle',position,label,'LineWidth',3,'Color',labelColor,'TextColor','black','FontSize',20);
