load '~/Dropbox/PhysioChallenge2017/Features/e3_allfeatures.mat'
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

predictorNames = names;
predictors = In;

% Train a classifier
% This code specifies all the classifier options and trains the classifier.
classificationEnsemble = fitensemble(...
    In, ...
    Out, ...
    'Bag', ...
    30, ...
    'Tree', ...
    'Type', 'Classification', ...
    'ClassNames', ['A'; 'N'; 'O'; '~']);

% Create the result struct with predict function
predictorExtractionFcn = @(t) t(:, predictorNames);
ensemblePredictFcn = @(x) predict(classificationEnsemble, x);
trainedClassifier.predictFcn = @(x) ensemblePredictFcn(predictorExtractionFcn(x));

% Add additional fields to the result struct
trainedClassifier.RequiredVariables = {'sample_AFEv', 'meanRR', 'medianRR', 'SDNN', 'RMSSD', 'SDSD', 'NN50', 'pNN50', 'totalpower', 'LFpower', 'HFpower', 'nLF', 'nHF', 'LFHF', 'PoincareSD1', 'PoincareSD2', 'sampleen', 'approxen', 'COSEn', 'RR', 'DET', 'ENTR', 'L', 'TKEO1', 'DFAa1', 'DAFa2', 'LZ', 'Clvl1', 'Clvl2', 'Clvl3', 'Clvl4', 'Clvl5', 'Clvl6', 'Clvl7', 'Clvl8', 'Clvl9', 'Clvl10', 'Dlvl1', 'Dlvl2', 'Dlvl3', 'Dlvl4', 'Dlvl5', 'Dlvl6', 'Dlvl7', 'Dlvl8', 'Dlvl9', 'Dlvl10', 'percR50', 'percR100', 'percR200', 'percR300', 'medRR', 'meddRR', 'iqrRR', 'iqrdRR', 'bins1', 'bins2', 'bins1nL', 'bins2nL', 'bins1nS', 'bins2nS', 'edgebins1', 'edgebins2', 'edgebins1nL', 'edgebins2nL', 'edgebins1nS', 'edgebins2nS', 'minArea', 'minAreanL', 'minAreanS', 'minCArea', 'minCAreanL', 'minCAreanS', 'Perim', 'PerimnL', 'PerimnS', 'PerimC', 'PerimCnL', 'PerimCnS', 'DistCen', 'DistCennL', 'DistCennS', 'DistNN', 'DistNNnL', 'DistNNnS', 'DistNext', 'DistNextnL', 'DistNextnS', 'ClustDistMax', 'ClustDistMin', 'ClustDistMean', 'ClustDistSTD', 'ClustDistMed', 'MajorAxis', 'MinorAxis', 'MinMajAxis', 'percR3', 'percR5', 'percR10', 'percR20', 'percR30', 'percR40', 'Xcent', 'Ycent', 'rad1', 'rad2', 'rad1rad2', 'theta', 'NoClust1', 'NoClust2', 'NoClust3', 'NoClust4', 'NoClust5', 'NoClust6', 'NoClust7', 'gentemp', 'numect', 'amp_varsqi_1', 'amp_varsqi_2', 'amp_varsqi_3', 'amp_varsqi_4', 'amp_varsqi_5', 'amp_varsqi_6', 'amp_stdsqi_1', 'amp_stdsqi_2', 'amp_stdsqi_3', 'amp_stdsqi_4', 'amp_stdsqi_5', 'amp_stdsqi_6', 'amp_meandiff_1', 'amp_meandiff_2', 'amp_meandiff_3', 'amp_meandiff_4', 'amp_meandiff_5', 'amp_meandiff_6', 'tachy', 'brady', 'flatline', 'stdsqi', 'ksqi', 'ssqi', 'psqi', 'bsqi_12', 'bsqi_13', 'bsqi_14', 'bsqi_15', 'bsqi_16', 'bsqi_23', 'bsqi_24', 'bsqi_25', 'bsqi_26', 'bsqi_34', 'bsqi_35', 'bsqi_36', 'bsqi_45', 'bsqi_46', 'bsqi_56', 'rsqi_1', 'rsqi_2', 'rsqi_3', 'rsqi_4', 'rsqi_5', 'rsqi_6', 'csqi_1', 'csqi_2', 'csqi_3', 'csqi_4', 'csqi_5', 'csqi_6', 'xsqi_1', 'xsqi_2', 'xsqi_3', 'xsqi_4', 'xsqi_5', 'xsqi_6'};
trainedClassifier.ClassificationEnsemble = classificationEnsemble;
trainedClassifier.About = 'This struct is a trained classifier exported from Classification Learner R2016a.';
trainedClassifier.HowToPredict = sprintf('To make predictions on a new table, T, use: \n  yfit = c.predictFcn(T) \nreplacing ''c'' with the name of the variable that is this struct, e.g. ''trainedClassifier''. \n \nThe table, T, must contain the variables returned by: \n  c.RequiredVariables \nVariable formats (e.g. matrix/vector, datatype) must match the original training data. \nAdditional variables are ignored. \n \nFor more information, see <a href="matlab:helpview(fullfile(docroot, ''stats'', ''stats.map''), ''appclassification_exportmodeltoworkspace'')">How to predict using an exported model</a>.');

% Extract predictors and response
% This code processes the data into the right shape for training the
% classifier.
inputTable = trainingData;
predictorNames = {'sample_AFEv', 'meanRR', 'medianRR', 'SDNN', 'RMSSD', 'SDSD', 'NN50', 'pNN50', 'totalpower', 'LFpower', 'HFpower', 'nLF', 'nHF', 'LFHF', 'PoincareSD1', 'PoincareSD2', 'sampleen', 'approxen', 'COSEn', 'RR', 'DET', 'ENTR', 'L', 'TKEO1', 'DFAa1', 'DAFa2', 'LZ', 'Clvl1', 'Clvl2', 'Clvl3', 'Clvl4', 'Clvl5', 'Clvl6', 'Clvl7', 'Clvl8', 'Clvl9', 'Clvl10', 'Dlvl1', 'Dlvl2', 'Dlvl3', 'Dlvl4', 'Dlvl5', 'Dlvl6', 'Dlvl7', 'Dlvl8', 'Dlvl9', 'Dlvl10', 'percR50', 'percR100', 'percR200', 'percR300', 'medRR', 'meddRR', 'iqrRR', 'iqrdRR', 'bins1', 'bins2', 'bins1nL', 'bins2nL', 'bins1nS', 'bins2nS', 'edgebins1', 'edgebins2', 'edgebins1nL', 'edgebins2nL', 'edgebins1nS', 'edgebins2nS', 'minArea', 'minAreanL', 'minAreanS', 'minCArea', 'minCAreanL', 'minCAreanS', 'Perim', 'PerimnL', 'PerimnS', 'PerimC', 'PerimCnL', 'PerimCnS', 'DistCen', 'DistCennL', 'DistCennS', 'DistNN', 'DistNNnL', 'DistNNnS', 'DistNext', 'DistNextnL', 'DistNextnS', 'ClustDistMax', 'ClustDistMin', 'ClustDistMean', 'ClustDistSTD', 'ClustDistMed', 'MajorAxis', 'MinorAxis', 'MinMajAxis', 'percR3', 'percR5', 'percR10', 'percR20', 'percR30', 'percR40', 'Xcent', 'Ycent', 'rad1', 'rad2', 'rad1rad2', 'theta', 'NoClust1', 'NoClust2', 'NoClust3', 'NoClust4', 'NoClust5', 'NoClust6', 'NoClust7', 'gentemp', 'numect', 'amp_varsqi_1', 'amp_varsqi_2', 'amp_varsqi_3', 'amp_varsqi_4', 'amp_varsqi_5', 'amp_varsqi_6', 'amp_stdsqi_1', 'amp_stdsqi_2', 'amp_stdsqi_3', 'amp_stdsqi_4', 'amp_stdsqi_5', 'amp_stdsqi_6', 'amp_meandiff_1', 'amp_meandiff_2', 'amp_meandiff_3', 'amp_meandiff_4', 'amp_meandiff_5', 'amp_meandiff_6', 'tachy', 'brady', 'flatline', 'stdsqi', 'ksqi', 'ssqi', 'psqi', 'bsqi_12', 'bsqi_13', 'bsqi_14', 'bsqi_15', 'bsqi_16', 'bsqi_23', 'bsqi_24', 'bsqi_25', 'bsqi_26', 'bsqi_34', 'bsqi_35', 'bsqi_36', 'bsqi_45', 'bsqi_46', 'bsqi_56', 'rsqi_1', 'rsqi_2', 'rsqi_3', 'rsqi_4', 'rsqi_5', 'rsqi_6', 'csqi_1', 'csqi_2', 'csqi_3', 'csqi_4', 'csqi_5', 'csqi_6', 'xsqi_1', 'xsqi_2', 'xsqi_3', 'xsqi_4', 'xsqi_5', 'xsqi_6'};
predictors = inputTable(:, predictorNames);
response = inputTable.Annotations;
isCategoricalPredictor = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false];

% Perform cross-validation
partitionedModel = crossval(trainedClassifier.ClassificationEnsemble, 'KFold', 10);

% Compute validation accuracy
validationAccuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');

% Compute validation predictions and scores
[validationPredictions, validationScores] = kfoldPredict(partitionedModel);
