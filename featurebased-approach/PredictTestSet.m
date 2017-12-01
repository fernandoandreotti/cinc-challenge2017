function PredictTestSet(recordName,varargin)
% This function predicts the corresponding ECG class of a given record
% using our feature based approach.
%
%
% Input
%   recordName: string specifying the record name to process
%   (optional inputs)
%           - useSegments:       segment signals into windows (bool)?
%           - windowSize:        size of window used in segmenting record
%           - percentageOverlap: overlap between windows
% --
% ECG classification from single-lead segments using Deep Convolutional Neural
% Networks and Feature-Based Approaches - December 2017
%
% Released under the GNU General Public License
%
% Copyright (C) 2017  Fernando Andreotti, Oliver Carr
% University of Oxford, Insitute of Biomedical Engineering, CIBIM Lab - Oxford 2017
% fernando.andreotti@eng.ox.ac.uk
%
%
% For more information visit: https://github.com/fernandoandreotti/cinc-challenge2017
%
% Referencing this work
%
% Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017).
% Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect
% Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).
%
% Last updated : December 2017
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

rng(1); % For reproducibility

%% Optional params
optargs = {1 10 0.8};  % default values for input arguments
newVals = cellfun(@(x) ~isempty(x), varargin);
optargs(newVals) = varargin(newVals);
[useSegments, windowSize, percentageOverlap] = optargs{:};
clear optargs newVals

%% Loading signal
[~,signal,fs,~]=rdmat(recordName);
disp(['Processing ' recordName '...'])
if size(signal,1) < size(signal,2); signal = signal'; end % column vector
if any(isnan(signal))
    signal = inpaint_nans(signal);                    % function to remove NaNs
end
signalraw =  signal;


% Parameters
NFEAT = 171; % number of features used
NFEAT_hrv = 113;


%% Initialize loop
% Wide BP
Fhigh = 5;  % highpass frequency [Hz]
Flow = 45;   % low pass frequency [Hz]
Nbut = 10;     % order of Butterworth filter
d_bp= design(fdesign.bandpass('N,F3dB1,F3dB2',Nbut,Fhigh,Flow,fs),'butter');
[b_bp,a_bp] = tf(d_bp);

% Narrow BP
Fhigh = 1;  % highpass frequency [Hz]
Flow = 100;   % low pass frequency [Hz]
Nbut = 10;     % order of Butterworth filter
d_bp= design(fdesign.bandpass('N,F3dB1,F3dB2',Nbut,Fhigh,Flow,fs),'butter');
[b_bp2,a_bp2] = tf(d_bp);
clear Fhigh Flow Nbut d_bp

%% Preprocessing
signal = filtfilt(b_bp,a_bp,signal);             % filtering narrow
signal = detrend(signal);                        % detrending (optional)
signal = signal - mean(signal);
signal = signal/std(signal);                     % standardizing
signalraw = filtfilt(b_bp2,a_bp2,signalraw);     % filtering wide
signalraw = detrend(signalraw);                  % detrending (optional)
signalraw = signalraw - mean(signalraw);
signalraw = signalraw/std(signalraw);        % standardizing
disp(['Preprocessed ' recordName '...'])

% Figuring out if segmentation is used
if useSegments==1
    WINSIZE = windowSize; % window size (in sec)
    OLAP = percentageOverlap;
else
    WINSIZE = length(signal)/fs;
    OLAP=0;
end
startp = 1;
endp = WINSIZE*fs;
looptrue = true;
nseg = 1;
while looptrue
    % Conditions to stop loop
    if length(signal) < WINSIZE*fs
        endp = length(signal);
        looptrue = false;
        continue
    end
    if nseg > 1
        startp(nseg) = startp(nseg-1) + round((1-OLAP)*WINSIZE*fs);
        if length(signal) - endp(nseg-1) < 0.5*WINSIZE*fs
            endp(nseg) = length(signal);
        else
            endp(nseg) = startp(nseg) + WINSIZE*fs -1;
        end
    end
    if endp(nseg) == length(signal)
        looptrue = false;
        nseg = nseg - 1;
    end
    nseg = nseg + 1;
end

%% Obtain features for each available segment
fetbag = {};
parfor n = 1:nseg
    % Get signal of interest
    sig_seg = signal(startp(n):endp(n));
    sig_segraw = signalraw(startp(n):endp(n));
    
    % QRS detect
    [qrsseg,featqrs] = multi_qrsdetect(sig_seg,fs,[recordName '_s' num2str(n)]);
    
    % HRV features
    if length(qrsseg{end})>5 % if too few detections, returns zeros
        try
            feat_basic=HRV_features(sig_seg,qrsseg{end}./fs,fs);
            feats_poincare = get_poincare(qrsseg{end}./fs,fs);
            feat_hrv = [feat_basic, feats_poincare];
            feat_hrv(~isreal(feat_hrv)|isnan(feat_hrv)|isinf(feat_hrv)) = 0; % removing not numbers
        catch
            warning('Some HRV code failed.')
            feat_hrv = zeros(1,NFEAT_hrv);
        end
    else
        disp('Skipping HRV analysis due to shortage of peaks..')
        feat_hrv = zeros(1,NFEAT_hrv);
    end
    
    % Heart Rate features
    HRbpm = median(60./(diff(qrsseg{end})));
    %obvious cases: tachycardia ( > 100 beats per minute (bpm) in adults)
    feat_tachy = normcdf(HRbpm,120,20); % sampling from normal CDF
    %See e.g.   x = 10:10:200; p = normcdf(x,120,20); plot(x,p)
    
    %obvious cases: bradycardia ( < 60 bpm in adults)
    feat_brady = 1-normcdf(HRbpm,60,20);
    
    % SQI metrics
    feats_sqi = ecgsqi(sig_seg,qrsseg,fs);
    
    % Features on residual
    featsres = residualfeats(sig_segraw,fs,qrsseg{end});
    
    % Morphological features
    feats_morph = morphofeatures(sig_segraw,fs,qrsseg,[recordName '_s' num2str(n)]);
    
    
    feat_fer=[featqrs,feat_tachy,feat_brady,double(feats_sqi),featsres,feats_morph];
    feat_fer(~isreal(feat_fer)|isnan(feat_fer)|isinf(feat_fer)) = 0; % removing not numbers
    
    % Save features to table for training
    feats = [feat_hrv,feat_fer];
    fetbag{n} = feats;
end
feats = cell2mat(fetbag');
% Standardizing input
feats = feats - nanmean(feats);
feats = feats./nanstd(feats);
feats(isnan(feats)) = 0;

NFEAT=size(feats,2);


delete('gqrsdet*.*')
clear fetbag b_bp b_bp2 endp looptrue signal signalraw startp useSegments windowSize
clear WINSIZE a_bp a_bp2 nseg OLAP percentageOverlap

%% Summarizing features

disp('Summarizing features ..')
featsum(1,1:NFEAT)=nanmean(feats);
featsum(1,1*NFEAT+1:2*NFEAT)=nanstd(feats);
if size(featsum,1)>2
    PCAn=pca(feats);
    featsum(1,2*NFEAT+1:3*NFEAT)=PCAn(:,1);
    featsum(1,3*NFEAT+1:4*NFEAT)=PCAn(:,2);
else
    featsum(1,2*NFEAT+1:3*NFEAT)=NaN;
    featsum(1,3*NFEAT+1:4*NFEAT)=NaN;
end
featsum(1,4*NFEAT+1:5*NFEAT)=nanmedian(feats);
featsum(1,5*NFEAT+1:6*NFEAT)=iqr(feats);
featsum(1,6*NFEAT+1:7*NFEAT)=range(feats);
featsum(1,7*NFEAT+1:8*NFEAT)=min(feats);
featsum(1,8*NFEAT+1:9*NFEAT)=max(feats);
featsum(1,9*NFEAT+1:10*NFEAT)=prctile(feats,25);
featsum(1,10*NFEAT+1:11*NFEAT)=prctile(feats,50);
featsum(1,11*NFEAT+1:12*NFEAT)=prctile(feats,75);
HIL=hilbert(feats);
featsum(1,12*NFEAT+1:13*NFEAT)=real(HIL(1,:));
featsum(1,13*NFEAT+1:14*NFEAT)=abs(HIL(1,:));
featsum(1,14*NFEAT+1:15*NFEAT)=skewness(feats);
featsum(1,15*NFEAT+1:16*NFEAT)=kurtosis(feats);

featsum(isnan(featsum)) = 0;

%% Using classifiers on feature table
% Loading classififers
slashchar = char('/'*isunix + '\'*(~isunix));
mainpath = (strrep(which(mfilename),['preparation' slashchar mfilename '.m'],''));
addpath(genpath([mainpath(1:end-length(mfilename)-2) 'classifiers' slashchar])) % add subfunctions folder to path

load('ensTree.mat')
load('nNets.mat')

% Performing classification
[~,probTree] = predict(ensTree_best,featsum);
probNN = nnet_best(featsum')';

prob = mean([probTree;probNN]);
[~,class] = max(prob);
labels = {'A' 'N' 'O' '~'};
fprintf('Recording %s labelled as %s (%2.2f percent certainty) .. \n',recordName,labels{class},prob(class))

