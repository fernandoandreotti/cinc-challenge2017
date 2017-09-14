load '~/Dropbox/PhysioChallenge2017/Features/e3_allfeatures.mat'

In = allfeats;
labels = {'N' 'A' 'O' '~'};
% ann_de = bi2de(ann_bin); ann_de(ann_de==4) = 3; ann_de(ann_de==8) = 4;
% 
% Out = ann_de;
Out = ann;
Nobs = length(Out);


%% Bagged trees (oversampled)
rng(1); % For reproducibility
%== Subset sampling
k = 10;
cv = cvpartition(Out,'kfold',k);
confusion = zeros(4,4,k);
for i=1:k
    trainidx = find(training(cv,i));
    testidx  = find(test(cv,i));
    trainidx = [trainidx ; repmat(trainidx(Out(trainidx)=='~'),4,1)]; %#ok<AGROW>
    trainidx = trainidx(randperm(length(trainidx)));
    ens = fitensemble(In(trainidx,:),Out(trainidx),'Bag',50,'Tree','type','classification');  
    estimate = predict(ens,In(testidx,:));
    confusion(:,:,i) = confusionmat(Out(testidx),estimate);    
end
confusion = sum(confusion,3);
F1 = zeros(1,4);
for i = 1:4
    F1(i)=2*confusion(i,i)/(sum(confusion(i,:))+sum(confusion(:,i)));
    fprintf('F1 measure for %s rhythm: %1.4f \n',labels{i},F1(i))
end
fprintf('Final F1 measure:  %1.4f\n',mean(F1))

%% Bagged trees + Neural Network (oversampled)
ann_bin = cell2mat(cellfun(@(x) ann == x,labels,'UniformOutput',0));
load('means')
load('stds')
normfeats=(In-repmat(means,Nobs,1))./repmat(stds,Nobs,1);

rng(1); % For reproducibility
%== Subset sampling
k = 10;
cv = cvpartition(Out,'kfold',k);
confusion = zeros(4,4,k);
for i=1:k
    trainidx = find(training(cv,i));
    testidx  = find(test(cv,i));
    trainidx = [trainidx ; repmat(trainidx(Out(trainidx)=='~'),4,1)]; %#ok<AGROW>
    trainidx = trainidx(randperm(length(trainidx)));
    %= Tree bagging
    ens = fitensemble(In(trainidx,:),Out(trainidx),'Bag',50,'Tree','type','classification'); 
    [~,probBag] = predict(ens,In(testidx,:));
    probBag = probBag(:,[2 1 3 4]);
    %= Neural net
    net = patternnet(10);
    [net,tr] = train(net,normfeats(trainidx,:)',double(ann_bin(trainidx,:))');
    probNN = net(normfeats(testidx,:)')';
    prob = cat(3,probBag,probNN);
    prob = mean(prob,3);
    [~,estimate] = max(prob,[],2);
    confusion(:,:,i) = confusionmat(Out(testidx),char(labels(estimate)'));    
end
confusion = sum(confusion,3);


F1 = zeros(1,4);
for i = 1:4
    F1(i)=2*confusion(i,i)/(sum(confusion(i,:))+sum(confusion(:,i)));
    fprintf('F1 measure for %s rhythm: %1.4f \n',labels{i},F1(i))
end
fprintf('Final F1 measure:  %1.4f\n',mean(F1))

