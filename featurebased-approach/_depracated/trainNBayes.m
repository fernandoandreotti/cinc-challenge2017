load '~/Dropbox/PhysioChallenge2017/Features/e3_allfeatures.mat'
load('means')
load('stds')
feats = num2cell(allfeats,1);
normfeats = arrayfun(@(x) (feats{x}-means(x))./stds(x),1:length(feats),'UniformOutput',false)
allfeats=cell2mat(normfeats);

indn = find(ann=='~');
ind1 = randsample(find(ann=='N'),5*length(indn),true);
ind2 = randsample(find(ann=='A'),5*length(indn),true);
ind3 = randsample(find(ann=='O'),5*length(indn),true);
indn = randsample(indn,5*length(indn),true);
allidx = [indn; ind1; ind2 ;ind3];
allidx = allidx(randperm(length(allidx)));
In = allfeats(allidx,:);
% In = allfeats;
% ann_de = zeros(size(ann));
% ann_de(ann == 'N') = 1;
% ann_de(ann == '~') = 2;
% ann_de(ann == 'O') = 3;
% ann_de(ann == 'A') = 4;
Out = ann(allidx);


naiveB = fitcnb(In,Out);
