% close all; %clear all;

% Load training data features for 10 sec segments
% load('test_allfeatures.mat')
load('C:\Users\shil3552\Dropbox\Cinc\test_allfeatures_tmp.mat')
% Load the classifier trained on the augmented data set
load('AugDataClassifier.mat')

ann=ann(1:3622);

% Classify each segment
feats=allfeats(:,3:end);
segmentClass = AugDataClassifier.predictFcn(feats);

% Create histogram for each training signal
for i=1:3622
    idx=find(table2array(allfeats(:,1))==i);
    lbls_now=segmentClass(idx);
    h_now(i,:)=histcounts(categorical(lbls_now),{'A','N','O','~'});
end

Nh_now=h_now./sum(h_now);

% Cross Validation
Out=ann;
k=10;
cv = cvpartition(Out,'kfold',k);
confusion = zeros(4,4,k);
for i=1:k
    clear est_lbl min_lbl prob_lab
    i
    trainidx = find(training(cv,i));
    testidx  = find(test(cv,i));
    trainidx = [trainidx ; repmat(trainidx(Out(trainidx)=='~'),4,1)]; %#ok<AGROW>
    trainidx = trainidx(randperm(length(trainidx)));
    
    hist_train=h_now(trainidx,:);
    
    [Ns,~]=size(hist_train);
    for j=1:length(testidx)   
        j
        hist_test_now=h_now(testidx(j),:);
        % Find the similarities between training histograms and current
        % test histogram
        
        % normalizing the histograms
        Nhist_test_now = hist_test_now ./sum(hist_test_now);
        Nhist_test_now = repmat(Nhist_test_now,[size(hist_train,1) 1]);
        Nhist_train = hist_train ./repmat(sum(hist_train,2),[1 size(hist_train,2)]);
        
        D1 = histcmp( hist_test_now, hist_train, 'sqeuclidean'); % Squared Euclidean
        D2 = histcmp( hist_test_now, hist_train, 'chisq');       % Chi Squared
        D3 =JSDiv(hist_train,hist_test_now);       % Jensen Shannon
        D4 = abs(1 - (max([Nhist_test_now(:,1)';Nhist_train(:,1)'])+max([Nhist_test_now(:,2)';Nhist_train(:,2)'])+...
            max([Nhist_test_now(:,3)';Nhist_train(:,3)'])+max([Nhist_test_now(:,4)';Nhist_train(:,4)']))); % Histogram intersection based distance
        D3=D3';
        
        % Combine similarities or choose one
%         D=D1;
        D=sum([(D1./sum(D1));(D2./sum(D2));(D3./sum(D3));(D4./sum(D4))]);
        
        % Find closest match to current test histogram
        min_val=min(D);
        ind_min=find(D==min_val);
        min_lbls=ann(trainidx(ind_min));
        min_lbl(:,j)=[ann(trainidx(ind_min));repmat('Z',[3000-length(ann(trainidx(ind_min))),1])];
        y={'A','N','O','~'};
        for z=1:4
            n(z)=length(find(strcmp(y(z),min_lbls)));
        end
        [~, itemp] = max(n);
        est_lbl(j)=y(itemp);
        
        prob_lab(j,1)=n(1)./sum(n);
        prob_lab(j,2)=n(2)./sum(n);
        prob_lab(j,3)=n(3)./sum(n);
        prob_lab(j,4)=n(4)./sum(n);
    end
    
    confusion(:,:,i) = confusionmat(Out(testidx),char(est_lbl'));    
end
labels = {'N' 'A' 'O' '~'};
confusion = sum(confusion,3);
F1 = zeros(1,4);
for i = 1:4
    F1(i)=2*confusion(i,i)/(sum(confusion(i,:))+sum(confusion(:,i)));
    fprintf('F1 measure for %s rhythm: %1.4f \n',labels{i},F1(i))
end
fprintf('Final F1 measure:  %1.4f\n',mean(F1))

t1=cell2table(cellstr(Out(testidx)));
t1.Properties.VariableNames={'Label'};
t2=cell2table(est_lbl');
t2.Properties.VariableNames={'Est_Label'};
t3=array2table(prob_lab);
t3.Properties.VariableNames={'A','N','O', 'Noise'};

prob=[t1,t2,t3];








