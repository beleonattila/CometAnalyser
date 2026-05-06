function C = semanticsegPatch(I, net, classNames, patchSize, stride, useGPU)
% Sliding window semantic segmentation for images larger than patchSize
%
% INPUT:
%   I           [H x W x 1] single grayscale image
%   net         Trained dlnetwork
%   classNames  String array of class names
%   patchSize   [pH x pW] patch size used during training
%   stride      [sH x sW] stride between patches (typically patchSize/2)
%
% OUTPUT:
%   C           Categorical segmentation map [H x W]

if nargin < 6
    useGPU = false;
end

% Move network to GPU if available
if useGPU
    net = dlupdate(@gpuArray, net);
end

[H, W, ~] = size(I);
pH = patchSize(1);  pW = patchSize(2);
sH = stride(1);     sW = stride(2);
numClasses = numel(classNames);

% Accumulator for softmax probabilities and count for averaging
probMap   = zeros(H, W, numClasses, 'single');
countMap  = zeros(H, W, 'single');

% Pad image so patches cover full image evenly
padH = ceil((H - pH) / sH) * sH + pH - H;
padW = ceil((W - pW) / sW) * sW + pW - W;
Ipad = padarray(I, [ceil(padH/2) ceil(padW/2)], 'replicate', 'both');

[Hp, Wp, ~] = size(Ipad);

% Slide window
for r = 1:sH:(Hp - pH + 1)
    for c = 1:sW:(Wp - pW + 1)
        % Extract patch
        patch = Ipad(r:r+pH-1, c:c+pW-1, :);

        % Move patch to GPU if needed
        if useGPU
            patchDL = dlarray(gpuArray(patch), 'SSC');
        else
            patchDL = dlarray(patch, 'SSC');
        end

        prob = gather(extractdata(predict(net, patchDL)));  % [pH x pW x numClasses]

        % Map back to original image coordinates
        r1 = r - ceil(padH/2);  r2 = r1 + pH - 1;
        c1 = c - ceil(padW/2);  c2 = c1 + pW - 1;

        % Clip to valid image region
        rStart = max(1, r1);    rEnd = min(H, r2);
        cStart = max(1, c1);    cEnd = min(W, c2);

        % Corresponding indices in patch
        prStart = rStart - r1 + 1;  prEnd = prStart + (rEnd - rStart);
        pcStart = cStart - c1 + 1;  pcEnd = pcStart + (cEnd - cStart);

        probMap(rStart:rEnd, cStart:cEnd, :) = ...
            probMap(rStart:rEnd, cStart:cEnd, :) + ...
            prob(prStart:prEnd, pcStart:pcEnd, :);

        countMap(rStart:rEnd, cStart:cEnd) = ...
            countMap(rStart:rEnd, cStart:cEnd) + 1;
    end
end

% Average overlapping predictions
probMap = probMap ./ countMap;

% Argmax to get class labels
[~, classIdx] = max(probMap, [], 3);
C = categorical(classIdx, 1:numClasses, classNames);
end