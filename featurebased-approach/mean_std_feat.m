clear feat

% Load training data features for 10 sec segments
% load('test_allfeatures.mat')
load('/data/PostDoc/scripts/af-classification/allfeatures_olap0.5_win10mixed.mat')
%allfeats = allfeats(:,1:149);
% allfeats=allfeats(:,[1:2,151:end]);

[n1,n2]=size(allfeats);
NF=n2-2;
% Get some summary statistics on the distribution of the features in each
% signal
feat = zeros(max(allfeats.rec_number),16*NF);
for i=1:length(ann)
    i
    ind=find(table2array(allfeats(:,1))==i);
    feat(i,1:NF)=nanmean(table2array(allfeats(ind,3:end)));
    feat(i,1*NF+1:2*NF)=nanstd(table2array(allfeats(ind,3:end)));
    if length(ind)>2
        PCAn=pca(table2array(allfeats(ind,3:end)));
        feat(i,2*NF+1:3*NF)=PCAn(:,1);
        feat(i,3*NF+1:4*NF)=PCAn(:,2);
    else
        feat(i,2*NF+1:3*NF)=NaN;
        feat(i,3*NF+1:4*NF)=NaN;
    end
    feat(i,4*NF+1:5*NF)=nanmedian(table2array(allfeats(ind,3:end)));
    feat(i,5*NF+1:6*NF)=iqr(table2array(allfeats(ind,3:end)));
    feat(i,6*NF+1:7*NF)=range(table2array(allfeats(ind,3:end)));
    feat(i,7*NF+1:8*NF)=min(table2array(allfeats(ind,3:end)));
    feat(i,8*NF+1:9*NF)=max(table2array(allfeats(ind,3:end)));
    feat(i,9*NF+1:10*NF)=prctile(table2array(allfeats(ind,3:end)),25);
    feat(i,10*NF+1:11*NF)=prctile(table2array(allfeats(ind,3:end)),50);
    feat(i,11*NF+1:12*NF)=prctile(table2array(allfeats(ind,3:end)),75);
    HIL=hilbert(table2array(allfeats(ind,3:end)));
    feat(i,12*NF+1:13*NF)=real(HIL(1,:));
    feat(i,13*NF+1:14*NF)=abs(HIL(1,:));
    feat(i,14*NF+1:15*NF)=skewness(table2array(allfeats(ind,3:end)));
    feat(i,15*NF+1:16*NF)=kurtosis(table2array(allfeats(ind,3:end))); 
end

% load('/data/PostDoc/scripts/af-classification/allfeatures_olap0_win7550mixed.mat')


% In = table2array(allfeats(:,3:end));
labels = {'A' 'N' 'O' '~'};
Ntrain = size(In,1);

In = feat;
% Normalize features
In(isnan(In)) = 0;
% ann_de = bi2de(ann_bin); ann_de(ann_de==4) = 3; ann_de(ann_de==8) = 4;
%
% Out = ann_de;
Out_all = ann;
Out = Out_all(1:8528,:); % Just using training set

Out = bi2de(Out);
Out(Out == 4) = 3;
Out(Out == 8) = 4;
%% Bagged trees (oversampled)
rng(1); % For reproducibility
%== Subset sampling
k = 5;
cv = cvpartition(Out,'kfold',k);
confusion = zeros(4,4,k);
ensave = {};
F1save = zeros(k,4);
Out = Out_all;
Out = bi2de(Out);
Out(Out == 4) = 3;
Out(Out == 8) = 4;
for i=1:k
    disp(i)
    trainidx = find(training(cv,i));
    trainidx = [trainidx; [8528:length(ann)]'];
    testidx  = find(test(cv,i));
    trainidx = trainidx(randperm(length(trainidx)));
    % Bagged trees
    ens = fitensemble(In(trainidx,:),Out(trainidx),'Bag',50,'Tree','type','classification');
    [estTree,probTree] = predict(ens,In(testidx,:));
    % Neural networks
    outbi = zeros(size(Out(trainidx),1),length(labels));
    for i = 1:length(labels)
        outbi(labels{i}==Out(trainidx),i) = 1;
    end
    Innorm = In - repmat(mean(In),Ntrain,1);
    Innorm = Innorm/repmat(std(Innorm),Ntrain,1);

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
%ens = compact(ensave{unique(max(mean(F1save,2),2))});











