function label=classifySegments(features,classifier)

% features is an N x M matrix of features for the current signal.
% N is the number of segments from the signal
% M is the number of features from each segment

% Label is the predicted class of the signal (cell, 'A', 'N', 'O' or '~')

[N,M]=size(features);

feat(1:M)=nanmean(features);
feat(1*M+1:2*M)=nanstd(features);
if N>2
    PCAn=pca(features);
    feat(2*M+1:3*M)=PCAn(:,1);
    feat(3*M+1:4*M)=PCAn(:,2);
else
    feat(2*M+1:3*M)=NaN;
    feat(3*M+1:4*M)=NaN;
end
feat(4*M+1:5*M)=nanmedian(features);
feat(5*M+1:6*M)=iqr(features);
feat(6*M+1:7*M)=range(features);
feat(7*M+1:8*M)=min(features);
feat(8*M+1:9*M)=max(features);
feat(9*M+1:10*M)=prctile(features,25);
feat(10*M+1:11*M)=prctile(features,50);
feat(11*M+1:12*M)=prctile(features,75);
HIL=hilbert(features);
feat(12*M+1:13*M)=real(HIL(1,:));
feat(13*M+1:14*M)=abs(HIL(1,:));
feat(14*M+1:15*M)=skewness(features);
feat(15*M+1:16*M)=kurtosis(features);

label=classifier.predict(feat);