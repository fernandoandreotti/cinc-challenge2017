function feats = morphofeatures(signal,fs,qrs,recordName)
%  This function obtains morphological features from raw ECG data.
%
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
fsnew = 250;
gain = 3000;
T_LENGTH = 200; % about a second
NB_BINS = 250;
Nfeats = 17;
% Bandpass filter for morphological analysis
Fhigh = 1;  % highpass frequency [Hz]
Flow = 100;   % low pass frequency [Hz]
Nbut = 12;     % order of Butterworth filter
d_bp= design(fdesign.bandpass('N,F3dB1,F3dB2',Nbut,Fhigh,Flow,fs),'butter');
[b_bp2,a_bp2] = tf(d_bp);
clear Fhigh Flow Nbut d_bp
signal = filtfilt(b_bp2,a_bp2,signal);               % filtering
signal = detrend(signal);

recordName = ['pu' recordName];
% Resampling for ECGPUWAVE
sigres=resample(signal,fsnew,fs);
qrsfinal = round(qrs{end}*fsnew/fs);


% Morphological features
%% Running ECGPUWAVE for normal beats
% == Using average normal beat
try
    [M,RES] = stackbeats(sigres,qrsfinal,T_LENGTH,NB_BINS);
    template = mean(M,2);
    template = resample(template,RES,NB_BINS);
    template = detrend(template);
    fake_sig = repmat(template,1,20);
    smoothvec = [0:0.1:0.9, ones(1,size(fake_sig,1)-20),0.9:-0.1:0]';
    fake_sig = bsxfun(@times,fake_sig,smoothvec); % smoothing edges
    fake_sig = reshape(fake_sig,[],1);
    fake_sig = detrend(fake_sig);
    tm = 1/fsnew:1/fsnew:length(fake_sig)/fsnew;
    tm = tm'-1/fsnew;
    [~,I] = max(abs(fake_sig));
    wsign = sign(fake_sig(I)); % looking for signal sign
    qrsfake = cumsum([0 repmat(RES,1,19)]) + floor(RES/2);
    fake_sig = 2*gain*wsign(1)*fake_sig/max(abs(fake_sig));
    wrsamp(tm,fake_sig,recordName,fsnew,gain,'')
    wrann(recordName,'qrs',qrsfake-1,repmat('N',length(qrsfake),1));
    if isunix
        system(['ecgpuwave -r ' recordName '.hea' ' -a ecgpu -i qrs']);
    else
       ecgpuwave(recordName,'ecgpu',[],[],'qrs'); % important to specify the QRS because it seems that ecgpuwave is crashing sometimes otherwise
    end
    [allref,alltypes_r] = rdann(recordName,'ecgpu');
    fake_sig = fake_sig./gain;
    featavgnorm = FECGSYN_QTcalc(alltypes_r,allref,fake_sig,fsnew);
    feats = struct2array(featavgnorm);
    feats(isnan(feats)) = 0;
catch
    warning('ecgpuwave NORMAL average has failed.')
    feats = zeros(1,Nfeats);
end

delete([recordName '.*'])

end

function feats = FECGSYN_QTcalc(ann_types,ann_stamp,signal,fs)

temp_types = ann_types;     % allows exclusion of unsuitable annotations
temp_stamp = ann_stamp;zeros(1,10);
feats = struct('QRSheight',0,'QRSwidth',0,'QRSpow',0,...
    'noPwave',0,'Pheight',0,'Pwidth',0,'Ppow',0,...
    'Theight',0,'Twidth',0,'Tpow',0,...
    'Theightnorm',0,'Pheightnorm',0,'Prelpow',0,...
    'PTrelpow',0,'Trelpow',0,'QTlen',0,'PRlen',0);

%== Treat biphasic T-waves
annstr = strcat({temp_types'});
idxbi=cell2mat(regexp(annstr,'tt')); % biphasic
nonbi2= cell2mat(regexp(annstr,'\)t\(')) +1; % weird t
nonbi3= cell2mat(regexp(annstr,'\)t\)')) +1; % weird t2
if sum(idxbi) > 0   % case biphasic waves occured
    posmax = [idxbi' idxbi'+1];
    [~,bindx]=max(abs(signal(ann_stamp(posmax))),[],2); % max abs value between tt
    clearidx = [idxbi+double(bindx'==1) nonbi2 nonbi3];
    %idxbi = idxbi + bindx -1; % new index to consider
    temp_types(clearidx) = [];    % clearing biphasic cases
    temp_stamp(clearidx) = [];
end

clear biphasic teesfollowed nonbi1 nonbi2 nonbi3 bindx clearidx posmax idxbi

%== Remove incomplete beats
comp=cell2mat(regexp(cellstr(temp_types'),'\(p\)\(N\)\(t\)')); % regular
beats = temp_stamp(cell2mat(arrayfun(@(x) x:x+8,comp','uniformoutput',0)));
skipP = false;
if isempty(beats)
    comp=cell2mat(regexp(cellstr(temp_types'),'\(t\)\(N\)\(t\)')); % missing P-wave
    if isempty(comp), return, end % if ECGPUWAVE does not really work then output zeros
    beats = temp_stamp(cell2mat(arrayfun(@(x) x:x+8,comp','uniformoutput',0)));
    skipP = true;
    feats.noPwave = 1;
else
    feats.noPwave = 0;
end

if size(beats,2)==1; beats = beats';end % case single beat is available
Pstart = beats(:,1);
validP = beats(:,2);
Pend = beats(:,3);
Rstart = beats(:,4);
validR = beats(:,5);
Rend = beats(:,6);
Tstart = beats(:,7);
validT = beats(:,8);
Tend = beats(:,9);

%% Calculating features
feats.QRSheight = abs(median(min([signal(Rstart) signal(Rend)],[],2) - signal(validR))); %        T-wave height
feats.QRSwidth = median(Rend - Rstart)/fs; %  T-wave width
feats.QRSpow = sum(signal(Rstart:Rend).^2);

if ~skipP
    feats.Pheight = abs(median(median([signal(Pstart) signal(Pend)],2) - signal(validP))); %        P-wave height
    feats.Pwidth = median(Pend - Pstart)/fs; %  P-wave width
    feats.Ppow = sum(signal(Pstart:Pend).^2);
end

feats.Theight = abs(median(median([signal(Tstart) signal(Tend)],2) - signal(validT))); %        T-wave height
feats.Twidth = median(Tend - Tstart)/fs; %  T-wave width
feats.Tpow = sum(signal(Tstart:Tend).^2);

feats.Theightnorm =  feats.Theight/feats.QRSheight;
feats.Trelpow = feats.Tpow/feats.QRSpow;

if ~skipP
    feats.Pheightnorm =  feats.Pheight/feats.QRSheight;
    feats.Prelpow = feats.Ppow/feats.QRSpow;
    feats.PTrelpow = feats.Ppow/feats.Tpow;
end

QT_MAX = 0.5*fs; % Maximal QT length (in s)  MAY VARY DEPENDING ON APPLICATION!
QT_MIN = 0.1*fs; % Minimal QT length (in s)  MAY VARY DEPENDING ON APPLICATION!
[~,dist] = dsearchn(Rstart,Tend);         % closest ref for each point in test qrs
feats.QTlen = median(dist(dist<QT_MAX&dist>QT_MIN))/fs;

if ~skipP
    PR_MAX = 0.3*fs; % Maximal QT length (in s)  MAY VARY DEPENDING ON APPLICATION!
    PR_MIN = 0.05*fs; % Minimal QT length (in s)  MAY VARY DEPENDING ON APPLICATION!
    [~,dist] = dsearchn(validP,validR);         % closest ref for each point in test qrs
    feats.PRlen = median(dist(dist<PR_MAX&dist>PR_MIN))/fs;
end

end
