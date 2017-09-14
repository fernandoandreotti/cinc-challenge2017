%--------------------------------------------------------------------------
clear;clc;close all

%--------------------------------------------------------------------------
% Load an example dataset provided with matlab
load '~/Dropbox/PhysioChallenge2017/Features/e3_allfeatures.mat'

% Balancing out
indn = find(ann=='~');
ind1 = randsample(find(ann=='N'),5*length(indn),true);
ind2 = randsample(find(ann=='A'),5*length(indn),true);
ind3 = randsample(find(ann=='O'),5*length(indn),true);
indn = randsample(indn,5*length(indn),true);
allidx = [indn; ind1; ind2 ;ind3];
allidx = allidx(randperm(length(allidx)));
In = allfeats(allidx,:);
% In = allfeats;
ann_de = zeros(size(ann));
ann_de(ann == 'N') = 1;
ann_de(ann == '~') = 2;
ann_de(ann == 'O') = 3;
ann_de(ann == 'A') = 4;
Out = ann(allidx);

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
tic
leaf=1;
ntrees=50;
surrogate='on';
disp('Training the tree bagger')
randFor = TreeBagger(...
        ntrees,...
        In,Out,... 
        'Method','classification',...
        'minleaf',leaf,...
        'Surrogate','on',...        
        'OOBPredictorImportance','on',...
        'Options',paroptions...
    );
toc

%--------------------------------------------------------------------------

imp = randFor.OOBPermutedPredictorDeltaError;
figure;
bar(imp);
title('Curvature Test');
ylabel('Predictor importance estimates');
xlabel('Predictors');
h = gca;
h.XTick = [1:length(names)];
h.XTickLabel = names;
h.XTickLabelRotation = 45;
h.TickLabelInterpreter = 'none';
[~,idx] = sort(imp,'descend');


% %--------------------------------------------------------------------------
% % Estimate Output using tree bagger
% disp('Estimate Output using tree bagger')
% x=Out;
% y=predict(b, In);
% name='Bagged Decision Trees Model';
% toc
% 
% %--------------------------------------------------------------------------
% % calculate the training data correlation coefficient
% cct=corrcoef(x,y);
% cct=cct(2,1);
% 
% %--------------------------------------------------------------------------
% % Create a scatter Diagram
% disp('Create a scatter Diagram')
% 
% % plot the 1:1 line
% plot(x,x,'LineWidth',3);
% 
% hold on
% scatter(x,y,'filled');
% hold off
% grid on
% 
% set(gca,'FontSize',18)
% xlabel('Actual','FontSize',25)
% ylabel('Estimated','FontSize',25)
% title(['Training Dataset, R^2=' num2str(cct^2,2)],'FontSize',30)
% 
% drawnow
% 
% fn='ScatterDiagram';
% fnpng=[fn,'.png'];
% print('-dpng',fnpng);
% 
% %--------------------------------------------------------------------------
% % Calculate the relative importance of the input variables
% tic
% disp('Sorting importance into descending order')
% weights=b.OOBPermutedVarDeltaError;
% [B,iranked] = sort(weights,'descend');
% toc
% 
% %--------------------------------------------------------------------------
% disp(['Plotting a horizontal bar graph of sorted labeled weights.']) 
% 
% %--------------------------------------------------------------------------
% figure
% barh(weights(iranked),'g');
% xlabel('Variable Importance','FontSize',30,'Interpreter','latex');
% ylabel('Variable Rank','FontSize',30,'Interpreter','latex');
% title(...
%     ['Relative Importance of Inputs in estimating Redshift'],...
%     'FontSize',17,'Interpreter','latex'...
%     );
% hold on
% barh(weights(iranked(1:10)),'y');
% barh(weights(iranked(1:5)),'r');
% 
% %--------------------------------------------------------------------------
% grid on 
% xt = get(gca,'XTick');    
% xt_spacing=unique(diff(xt));
% xt_spacing=xt_spacing(1);    
% yt = get(gca,'YTick');    
% ylim([0.25 length(weights)+0.75]);
% xl=xlim;
% xlim([0 2.5*max(weights)]);
% 
% %--------------------------------------------------------------------------
% % Add text labels to each bar
% for ii=1:length(weights)
%     text(...
%         max([0 weights(iranked(ii))+0.02*max(weights)]),ii,...
%         ['Column ' num2str(iranked(ii))],'Interpreter','latex','FontSize',11);
% end
% 
% %--------------------------------------------------------------------------
% set(gca,'FontSize',16)
% set(gca,'XTick',0:2*xt_spacing:1.1*max(xl));
% set(gca,'YTick',yt);
% set(gca,'TickDir','out');
% set(gca, 'ydir', 'reverse' )
% set(gca,'LineWidth',2);   
% drawnow
% 
% %--------------------------------------------------------------------------
% fn='RelativeImportanceInputs';
% fnpng=[fn,'.png'];
% print('-dpng',fnpng);
% 
% %--------------------------------------------------------------------------
% % Ploting how weights change with variable rank
% disp('Ploting out of bag error versus the number of grown trees')
% 
% figure
% plot(b.oobError,'LineWidth',2);
% xlabel('Number of Trees','FontSize',30)
% ylabel('Out of Bag Error','FontSize',30)
% title('Out of Bag Error','FontSize',30)
% set(gca,'FontSize',16)
% set(gca,'LineWidth',2);   
% grid on
% drawnow
% fn='EroorAsFunctionOfForestSize';
% fnpng=[fn,'.png'];
% print('-dpng',fnpng);
