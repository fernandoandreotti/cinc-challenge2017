function SegmentClassifier(feature_file)


load(feature_file)
NFEAT=size(allfeats,2);
NFEAT=NFEAT-2;
% Get some summary statistics on the distribution of the features in each
% signal
feat = zeros(max(allfeats.rec_number),16*NFEAT);
for i=1:max(allfeats.rec_number)
    fprintf('Processing record %d .. \n',i)
    ind=find(table2array(allfeats(:,1))==i);
    feat(i,1:NFEAT)=nanmean(table2array(allfeats(ind,3:end)));
    feat(i,1*NFEAT+1:2*NFEAT)=nanstd(table2array(allfeats(ind,3:end)));
    if length(ind)>2
        PCAn=pca(table2array(allfeats(ind,3:end)));
        feat(i,2*NFEAT+1:3*NFEAT)=PCAn(:,1);
        feat(i,3*NFEAT+1:4*NFEAT)=PCAn(:,2);
    else
        feat(i,2*NFEAT+1:3*NFEAT)=NaN;
        feat(i,3*NFEAT+1:4*NFEAT)=NaN;
    end
    feat(i,4*NFEAT+1:5*NFEAT)=nanmedian(table2array(allfeats(ind,3:end)));
    feat(i,5*NFEAT+1:6*NFEAT)=iqr(table2array(allfeats(ind,3:end)));
    feat(i,6*NFEAT+1:7*NFEAT)=range(table2array(allfeats(ind,3:end)));
    feat(i,7*NFEAT+1:8*NFEAT)=min(table2array(allfeats(ind,3:end)));
    feat(i,8*NFEAT+1:9*NFEAT)=max(table2array(allfeats(ind,3:end)));
    feat(i,9*NFEAT+1:10*NFEAT)=prctile(table2array(allfeats(ind,3:end)),25);
    feat(i,10*NFEAT+1:11*NFEAT)=prctile(table2array(allfeats(ind,3:end)),50);
    feat(i,11*NFEAT+1:12*NFEAT)=prctile(table2array(allfeats(ind,3:end)),75);
    HIL=hilbert(table2array(allfeats(ind,3:end)));
    feat(i,12*NFEAT+1:13*NFEAT)=real(HIL(1,:));
    feat(i,13*NFEAT+1:14*NFEAT)=abs(HIL(1,:));
    feat(i,14*NFEAT+1:15*NFEAT)=skewness(table2array(allfeats(ind,3:end)));
    feat(i,15*NFEAT+1:16*NFEAT)=kurtosis(table2array(allfeats(ind,3:end))); 
end

In = feat;
Ntrain = size(In,1);
In(isnan(In)) = 0;
% Standardizing input
In = In - mean(In);
In = In./std(In);

labels = {'A' 'N' 'O' '~'};
Out = reference_tab{:,2};
Outbi = cell2mat(cellfun(@(x) strcmp(x,labels),Out,'UniformOutput',0));
Outde = bi2de(Outbi);
Outde(Outde == 4) = 3;
Outde(Outde == 8) = 4;
clear Out
%% Bagged trees (oversampled)
rng(1); % For reproducibility
%== Subset sampling
k = 5;
cv = cvpartition(Outde,'kfold',k);
confusion = zeros(4,4,k);
ensave = {};
F1save = zeros(k,4);
for i=1:k
    fprintf('Cross-validation loop %d \n',i)
    trainidx = find(training(cv,i));
    trainidx = trainidx(randperm(length(trainidx)));
    testidx  = find(test(cv,i));
    % Bagged trees
    ens = fitensemble(In(trainidx,:),Outde(trainidx),'Bag',50,'Tree','type','classification');
    [estTree,probTree] = predict(ens,In(testidx,:));
    % Neural networks
    net = patternnet(10);
    net = train(net,Innorm(trainidx,:)',outbi');            
    probNN = net(Innorm(testidx,:)')';    

    C = cat(3,probTree,probNN);
    C = mean(C,3);
    estimate = zeros(size(C,1),1);
    for r = 1:size(C,1)
        [~,estimate(r)] = max(C(r,:));
    end
%     estimate = estTree;
    confmat = confusionmat(Out(testidx),estimate);
    confusion(:,:,i) = confmat;
    ensave{i} = ens;
    F1 = zeros(1,4);
    for j = 1:4
        F1(j)=2*confmat(j,j)/(sum(confmat(j,:))+sum(confmat(:,j)));
        fprintf('F1 measure for %s rhythm: %1.4f \n',labels{j},F1(j))
    end
    F1save(i,:) = F1;
end
confusion = sum(confusion,3);
F1 = zeros(1,4);
for i = 1:4
    F1(i)=2*confusion(i,i)/(sum(confusion(i,:))+sum(confusion(:,i)));
    fprintf('F1 measure for %s rhythm: %1.4f \n',labels{i},F1(i))
end
fprintf('Final F1 measure:  %1.4f\n',mean(F1))











