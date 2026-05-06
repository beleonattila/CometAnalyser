function loss = weightedCrossEntropy(Y, T, classWeights)
% AUTHOR: Attila Beleon
% DATE: April 28, 2026
% NAME: weightedCrossEntropy
%
% Manual per-pixel weighting — avoids WeightsFormat API issues
% Build per-pixel weight map
weights = sum(T .* reshape(classWeights, 1, 1, []), 3);  % [H x W x 1 x B]

% Compute unweighted per-pixel loss
loss = crossentropy(Y, T, 'Reduction', 'none');           % [H x W x 1 x B]

% Apply weights manually and average
loss = loss .* weights;
loss = mean(loss, 'all');
end