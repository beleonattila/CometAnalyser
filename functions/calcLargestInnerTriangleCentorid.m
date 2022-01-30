function centroid = calcLargestInnerTriangleCentorid(mask)

BW = bwperim(mask);
[x,y] = find(BW);
dT = delaunay(x,y);
xT = reshape(x(dT), size(dT)); % X coordinates of vertices in triangulation
yT = reshape(y(dT), size(dT)); % Y coordinates of vertices in triangulation
areaT = abs((xT(:, 2) - xT(:, 1)) .* (yT(:, 3) - yT(:, 1)) - ...
    (xT(:, 3) - xT(:, 1)) .* (yT(:, 2) - yT(:, 1)))/2;

centroidTri = round([mean(xT,2) mean(yT,2)]);
[~, sortedID] = sort(areaT);

for i = 1:numel(sortedID)
    if mask(centroidTri(sortedID(i),1),centroidTri(sortedID(i),2)) > 0
        centroid = centroidTri(sortedID(i),:);
        break
    end
end