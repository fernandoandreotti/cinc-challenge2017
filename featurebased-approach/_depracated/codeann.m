% Using this routine to try out some neural networks

%% Load data
load('/local/engs1314/Dropbox/PhysioChallenge2017/Features/allfeatures.mat')
t=array2table(allfeats,'VariableNames',names);
t.Annotations = ann;
% Coding annotations
ann_de = zeros(size(ann));
ann_de(ann == 'N') = 1;
ann_de(ann == '~') = 2;
ann_de(ann == 'O') = 3;
ann_de(ann == 'A') = 4;
ann_bin = de2bi(ann_de);
ann_de = ann_de';

%% Training Trees
target = ann_de;
features = allfeats;
conf1sum = zeros(4,4);

% %== Cross k-fold validation
% numberCV=10; % cross-fold validation
% cp = cvpartition(target,'KFold',numberCV);
% quality = zeros(numberCV,1);
% qual = classperf(target); % initializes the CP object
% for j = 1:cp.NumTestSets
%     trIdx = cp.training(j);
%     teIdx = cp.test(j);    
% 
%     features(trIdx,:),target(trIdx,:) % train
%     
%     features(teIdx,:),target(teIdx,:) % test
%     conf1sum = conf1sum + confusionmat(target(teIdx),estimate);
% 
% end
% ens = fitensemble(features,classes,'bag',50,'tree','Type','regression')
% estimate=ens.predict(features)


ClassTreeEns = fitensemble(features,target,'RUSBoost',100,'Tree');
estimate=ClassTreeEns.predict(features);
confusionmat(target,estimate);



%== Subset sampling
numberOfRuns = 100;
sizeOfElementsPerRun = 50;

for i=1:numberOfRuns
 classes=unique(target);
 currentFeatures=[];
 currentObjectiveValues=[];
 for actualClass=1:numel(classes)
     classIndices=find(target==classes(actualClass));
     randomIndices=randsample(classIndices,sizeOfElementsPerRun,true);         
     currentFeatures(end+1:end+sizeOfElementsPerRun,:)=features(randomIndices,:);
     currentObjectiveValues(end+1:end+sizeOfElementsPerRun,:)=classes(actualClass);
 end
 
  % do training and apply model

%     ens = fitensemble(currentFeatures,currentObjectiveValues,'bag',50,'tree');
    ClassTreeEns = fitensemble(currentFeatures,currentObjectiveValues,'RUSBoost',100,'Tree');
    estimate=ClassTreeEns.predict(currentFeatures);
    conf1sum = conf1sum + confusionmat(currentObjectiveValues,estimate);
    
end

F1n=2*conf1sum(1,1)/(sum(conf1sum(1,:))+sum(conf1sum(:,1)));
F1a=2*conf1sum(2,2)/(sum(conf1sum(2,:))+sum(conf1sum(:,2)));
F1o=2*conf1sum(3,3)/(sum(conf1sum(3,:))+sum(conf1sum(:,3)));
F1p=2*conf1sum(4,4)/(sum(conf1sum(4,:))+sum(conf1sum(:,4)));
F1=(F1n+F1a+F1o+F1p)/4;

%% Feature selection?
[ranked,weights]=relieff(featmat,ann_de,10);
bar(weights(ranked));

%% Deep Net?
% Train an autoencoder with a hidden layer of size 10 and a linear transfer 
% function for the decoder. Set the L2 weight regularizer to 0.001, sparsity 
% regularizer to 4 and sparsity proportion to 0.05.
hiddenSize = 10;
autoenc1 = trainAutoencoder(featmat',hiddenSize,...
    'L2WeightRegularization',0.001,...
    'SparsityRegularization',4,...
    'SparsityProportion',0.05,...
    'DecoderTransferFunction','purelin');

% Extract the features in the hidden layer.
features1 = encode(autoenc1,featmat');

% Train a second autoencoder using the features from the first autoencoder. Do not scale the data.
hiddenSize = 10;
autoenc2 = trainAutoencoder(features1,hiddenSize,...
    'L2WeightRegularization',0.001,...
    'SparsityRegularization',4,...
    'SparsityProportion',0.05,...
    'DecoderTransferFunction','purelin',...
    'ScaleData',false);


% Extract the features in the hidden layer.
features2 = encode(autoenc2,features1);

% Train a softmax layer for classification using the features, features2, from the second autoencoder, autoenc2.
softnet = trainSoftmaxLayer(features2,ann_bin,'LossFunction','crossentropy');

% Stack the encoders and the softmax layer to form a deep network.
deepnet = stack(autoenc1,autoenc2,softnet);

% Train the deep network on the wine data.
deepnet = train(deepnet,featmat',ann_bin);

% Estimate the wine types using the deep network, deepnet.
wine_type = deepnet(featmat');

% Plot the confusion matrix.
plotconfusion(ann_bin,wine_type);