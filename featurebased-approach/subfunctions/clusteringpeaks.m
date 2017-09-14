function clusteringpeaks
Nclus = 100; % number of clusters
windows = buffer(signal, round(0.2*fs), round(0.1*fs));
mutate = bsxfun(@times,windows,hamming(round(0.2*fs)));
points = mutate.';
cleanPoints = points(2:end-1, :);
[~, clusters, ~] = fkmeans(cleanPoints,Nclus);

%% Noise transformation
samples = cleanPoints(1:300, :);
clusterIndices = nearKmean(clusters, samples);
diffWindows = diffKmean(clusterIndices, clusters, samples);




function clusterIndices = nearKmean(clusters, samples)
numObservarations = size(samples,1);
K = size(clusters,1);
D = zeros(numObservarations, K);
for k=1:K
 %d = sum((x-y).^2).^0.5
 D(:,k) = sum( ((data - repmat(clusters(k,:),numObservarations,1)).^2), 2);
end
[minDists, clusterIndices] = min(D, [], 2);
end