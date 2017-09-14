function challenge_new
% Defining path (for windows and linux)
slashchar = char('/'*isunix + '\'*(~isunix));
mainpath = (strrep(which(mfilename),['preparation' slashchar mfilename '.m'],''));
addpath(genpath([mainpath 'subfunctions' slashchar])) % add subfunctions folder to path

dbpath =  [mainpath slashchar 'preparation' slashchar 'training2017' slashchar];
if isunix
    spath = '~/Dropbox/PhysioChallenge2017/Features/'; % saving path
else
    spath = dbpath;
end

%% Parameters
Nfeatfern = 58; % number of features, CHANGE!!
Nfeatoli = 111;
Nfeats = Nfeatoli + Nfeatfern;
Ndet = 5;

% Find recordings
cd([mainpath 'preparation' slashchar])
filename = [dbpath 'REFERENCE-v2.csv'];
delimiter = ',';
formatSpec = '%q%q%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
fls = dataArray{1};
ann = char(dataArray{2});
% Output log
% diary('log.txt')
% diary on
clear dataArray delimiter filename
%% Close the text file.
fclose(fileID);
tab_output = cell(length(fls),Nfeats+2);
tab_output(:,1:2) = [fls cellstr(ann)];
% persistent allfeats
allfeats = zeros(length(fls), Nfeats);

fs = 300;
Fhigh = 5;  % highpass frequency [Hz]
Flow = 45;   % low pass frequency [Hz]
Nbut = 10;     % order of Butterworth filter
d_bp= design(fdesign.bandpass('N,F3dB1,F3dB2',Nbut,Fhigh,Flow,fs),'butter');
[b_bp,a_bp] = tf(d_bp);
clear Fhigh Flow Nbut d_bp

% Run through files

parfor f = 1:length(fls)
    %% Loading data
    data = myLoadData([dbpath fls{f} '.mat']);
    fname = fls{f};
    signal = data.val;
    disp(['Processing ' fname '...'])
    %% Preprocessing
    if size(signal,1) < size(signal,2); signal = signal'; end % column vector
    if any(isnan(signal))
        signal = inpaint_nans(signal);                    % function to remove NaNs
        %        signal(isnan(signal)) = 0;                         % alternative
    end
    signalraw = signal;
    f
    signal = filtfilt(b_bp,a_bp,signal);               % filtering
    signal  = (signal - mean(signal))./std(signal);    % normalizing
    signal = detrend(signal);
    signalraw =  detrend(signalraw);
    
    %% QRS Detection (multiple methods)
    [qrs,feats_morph,ect_qrs]=multi_qrsdetect(signal,fs,fname); % cell output
    
    [SigSegments,QRSsegments]=segment_QRS(qrs{end},signal,fs,10,0.5);

    % Oliver features
    try
        feat_basic=oliver_features(signal,qrs{end},fs);
        feats_poincare = get_poincare(qrs{end},fs);
        feat_oli = [feat_basic feats_poincare];
        feat_oli(~isreal(feat_oli)|isnan(feat_oli)|isinf(feat_oli)) = 0; % removing not numbers
    catch
        warning('Some HRV feature failed.')
        feat_oli = zeros(1,Nfeatoli);
    end
    
    % Fernando features
    HRbpm = median(60./(diff(qrs{end})/fs));
    obvious cases: tachycardia ( > 100 beats per minute (bpm) in adults)
    feat_tachy = normcdf(HRbpm,120,20); % sampling from normal CDF
    See e.g.   x = 10:10:200; p = normcdf(x,120,20); plot(x,p)
    
    obvious cases: bradycardia ( < 60 bpm in adults)
    feat_brady = 1-normcdf(HRbpm,60,20);
    
    feats_sqi = ecgsqi(signal,qrs,fs);
    feats_morph2 = morphofeatz(signalraw,fs,qrs,ect_qrs,fname);
    
    
    feat_fer=[feats_morph feat_tachy feat_brady double(feats_sqi) feats_morph2];
    feat_fer(~isreal(feat_fer)|isnan(feat_fer)|isinf(feat_fer)) = 0; % removing not numbers
    
    % Save features to table for training
    feats = [feat_oli   feat_fer];
    allfeats(f,:) = feats;
    
%     % Print figures
%     figure(f)
%     set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);  
%     subplot(2,1,1)
%     plot(signal)
%     title({['Rec: ' fname] ; ['Label: ' ann(f)]},'Interpreter','none');
%     hold on
%     plot(qrs{end-1},signal(qrs{end-1}),'xb')
%     plot(qrs{end},signal(qrs{end}),'or')
%     subplot(2,1,2)
%     plot(qrs{end}(2:end),diff(qrs{end})*1000/fs)
%     ylabel('RR intervals (ms)')
%     ylim([250 1300])
%     saveas(gcf,[mainpath 'plots/' fls{f} '.jpg']);
    close
end
delete('gqrsdet*.*')
% diary off
%% Saving Output
names = {'sample_AFEv' 'meanRR' 'medianRR' 'SDNN' 'RMSSD' 'SDSD' 'NN50' 'pNN50' 'totalpower' 'LFpower' ...
    'HFpower' 'nLF' 'nHF' 'LFHF' 'PoincareSD1' 'PoincareSD2' 'sampleen' ...
    'approxen' 'COSEn' 'RR' 'DET' 'ENTR' 'L' 'TKEO1'  'DFAa1' 'DAFa2' 'LZ' ...
    'Clvl1' 'Clvl2' 'Clvl3' 'Clvl4' 'Clvl5' 'Clvl6' 'Clvl7' 'Clvl8' 'Clvl9' ...
    'Clvl10' 'Dlvl1' 'Dlvl2' 'Dlvl3' 'Dlvl4' ...
    'Dlvl5' 'Dlvl6' 'Dlvl7' 'Dlvl8' 'Dlvl9' 'Dlvl10' ...
    'percR50' 'percR100' 'percR200' 'percR300' 'medRR' 'meddRR' 'iqrRR' 'iqrdRR' 'bins1' 'bins2' 'bins1nL' 'bins2nL' 'bins1nS' 'bins2nS' ...
    'edgebins1' 'edgebins2' 'edgebins1nL' 'edgebins2nL' 'edgebins1nS' 'edgebins2nS' 'minArea' 'minAreanL' 'minAreanS' ...
    'minCArea' 'minCAreanL' 'minCAreanS' 'Perim' 'PerimnL' 'PerimnS' 'PerimC' 'PerimCnL' 'PerimCnS' ...
    'DistCen' 'DistCennL' 'DistCennS' 'DistNN' 'DistNNnL' 'DistNNnS' 'DistNext' 'DistNextnL' 'DistNextnS' 'ClustDistMax' 'ClustDistMin' ...
    'ClustDistMean' 'ClustDistSTD' 'ClustDistMed' 'MajorAxis' 'percR3' 'percR5' 'percR10' 'percR20' 'percR30' 'percR40' ...
    'Xcent' 'Ycent' 'rad1' 'rad2' 'rad1rad2' 'theta' 'NoClust1' 'NoClust2' 'NoClust3' 'NoClust4' 'NoClust5' 'NoClust6' 'NoClust7'};
names = [names 'gentemp' 'numect'];
names = [names arrayfun(@(x) strtrim(['amp_varsqi_',num2str(x)]),1:Ndet,'UniformOutput',false)];
names = [names arrayfun(@(x) strtrim(['amp_stdsqi_',num2str(x)]),1:Ndet,'UniformOutput',false)];
names = [names arrayfun(@(x) strtrim(['amp_meandiff_',num2str(x)]),1:Ndet,'UniformOutput',false)];
names = [names 'tachy' 'brady' 'stdsqi' 'ksqi' 'ssqi' 'psqi'];

combs = nchoosek(1:Ndet,2);
combs = num2cell(combs,2);
names = [names cellfun(@(x) strtrim(['bsqi_',num2str(x(1)) num2str(x(2))]),combs,'UniformOutput',false)'];
names = [names arrayfun(@(x) strtrim(['rsqi_',num2str(x)]),1:Ndet,'UniformOutput',false)];
names = [names arrayfun(@(x) strtrim(['csqi_',num2str(x)]),1:Ndet,'UniformOutput',false)];
names = [names arrayfun(@(x) strtrim(['xsqi_',num2str(x)]),1:Ndet,'UniformOutput',false)];
names = [names 'avgPheight' 'avgPwidth' 'avgQRSheight' 'avgQRSwidth' 'avgTheight' ...
    'avgTwidth' 'avgTheightnorm' 'avgPheightnorm' 'avgQTlen' 'avgPRlen' ...
    'abavgPheight' 'abavgPwidth' 'abavgQRSheight' 'abavgQRSwidth' 'abavgTheight' ...
    'abavgTwidth' 'abavgTheightnorm' 'abavgPheightnorm' 'abavgQTlen' 'abavgPRlen' ...
    'dPheight' 'dPwidth' 'dQRSheight' 'dQRSwidth'  'dTheight' ...
    'dTwidth' 'dTheightnorm' 'dPheightnorm' 'dQTlen' 'dPRlen'];

append = 'test_';
save([spath append 'allfeatures.mat'],'allfeats','ann','names');

% %% Save as CSV
tab_output(:,3:end)=num2cell(allfeats);
tab_output = table(tab_output);
tab_output.Properties.VariableNames = ['Record' 'Reference' names];
writetable(tab_output,[spath append 'allfeaturesOliver.csv'])
%% Classifying using new features

% T = array2table(feats,'VariableNames',names);
% T.Annotation = ann;
% Tsel = T(:,[1,2,5,11,17,24,38,45,58,64,72,78,83,100,107,108,113,123,136,137,147,154,156,163,169,175,176]);


% %% Generating scores
% [AA,lab] = confusionmat(ann,estimated); % create confusion matrix
% F1 = zeros(1,4);
% for i = 1:4
%     F1(i)=2*AA(i,i)/(sum(AA(i,:))+sum(AA(:,i)));
%     fprintf('F1 measure for %s rhythm: %1.4f \n',lab(i),F1(i))
% end
% fprintf('Final F1 measure:  %1.4f\n',mean(F1))


end
% loads data in parfor loop
function myData = myLoadData(fname)

myData = load(fname);


end