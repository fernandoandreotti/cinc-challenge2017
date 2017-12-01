function [qrs,feats]=multi_qrsdetect(signal,fs,fname)
% This function detects QRS peaks on ECG signals by taking the consensus of multiple algorithms, namely:
%    - gqrs (WFDB Toolbox)
%    - Pan-Tompkins (FECGSYN)
%    - Maxima Search (OSET/FECGSYN)
%    - matched filtering
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

qrs = cell(1,5); % CHANGE ME! Using 6 levels of detection

WIN_ALG = round(0.08*fs); % 100ms allow re-alignment of 80ms for gqrs
REF_WIN = round(0.17*fs);    % refractory window PT algorithm, no detection should occur here.
WIN_BLOCK = round(5*fs);    % window for PT algorithm
OLAP = round(1*fs);
MIRR = round(2*fs);           % length to mirror signal at beginning and end to avoid border effects

LEN = length(signal);
signal = [signal(1:MIRR); signal ; signal(LEN-MIRR+1:LEN)];
LEN = LEN + 2*MIRR;
%% gQRS
try
    recordName = ['gd_' fname];
    tm = 1/fs:1/fs:LEN/fs;

    wrsamp(tm',signal,recordName,fs,1)
    disp(['Running gqrs ' fname '...'])
    if isunix                 
        system(['gqrs -r ' recordName ' -f 0 -s 0']);
        disp(['gqrs ran ' fname '...'])
    else
       gqrs(recordName)
    end
    qrs{1} = rdann(recordName,'qrs');        
    disp(['read gqrs output ' fname '...'])
    
    [~,lag]=arrayfun(@(x) max(abs(signal(x-WIN_ALG:x+WIN_ALG))),qrs{1}(2:end-1));
    qrs{1}(2:end-1) = qrs{1}(2:end-1) + lag - WIN_ALG - 1;
    delete([recordName '.*'])
catch
    warning('gqrs failed.')
    delete([recordName '.*'])
    qrs{1} = [];
end
clear lag tm recordName

%% P&T algorithm (in windows of 5 seconds - 1 sec overlap)
try
    disp(['Running jqrs ' fname '...'])
    qrs{2} = jqrs(signal,REF_WIN,[],fs,[],[],0);
catch
    warning('Pan Tompkins failed.')
    qrs{2} = [];
end

clear qrs_tmp startp endp count
%% MaxSearch (mQRS)
qrsmax=qrs{double(length(qrs{2})>length(qrs{1}))+1}; % selecting as reference detector with most detections
try
    disp(['Running maxsearch ' fname '...'])
    if length(qrsmax)<5
        HR_PARAM = 1.3; % default value
    else
        HR_PARAM = fs./nanmedian(diff(qrsmax))+0.1;  % estimate rate (in Hz) for MaxSearch
    end
    
    qrs{3} = OSET_MaxSearch(signal,HR_PARAM/fs)';
catch
    warning('MaxSearch failed.')
    qrs{3} = [];
end


% Put all detectors on same sign (max or min) - shift by median lag
x = decimate(signal,5);    % just to reduce calculus
y = sort(x);    
flag = mean(abs(y(round(end-0.05*length(y)):end)))>mean(abs(y(1:round(0.05*length(y)))));
for i = 1:length(qrs)
    if flag
        [~,lag]=arrayfun(@(x) max(signal(x-WIN_ALG:x+WIN_ALG)),qrs{i}(3:end-2));
    else
        [~,lag]=arrayfun(@(x) min(signal(x-WIN_ALG:x+WIN_ALG)),qrs{i}(3:end-2));
    end
    qrs{i}(3:end-2) = qrs{i}(3:end-2) + lag - WIN_ALG - 1;
end

clear HR_PARAM qrsmax


%% Matched filtering QRS detection
try
    disp(['Running matchedfilter ' fname '...'])
    [btype,templates,tempuncut] = beat_class(signal,qrs{3},round(WIN_ALG));
    [qrs{4},ect_qrs]=matchedQRS(signal,templates,qrs{3},btype);
    matchedf = 1; % status signal used as feature
catch
    warning('Matched filter failed.')
    disp('Matched filter failed.')
    qrs{4} = [];
    ect_qrs = [];
    matchedf = 0;
end


%% Consensus detection
try
    consqrs = kde_fusion(cell2mat(qrs(1:4)'),fs,length(signal)); % 2x gqrs
    consqrs(diff(consqrs)<REF_WIN) = []; % removing double detections
    [~,lag]=arrayfun(@(x) max(abs(signal(x-WIN_ALG:x+WIN_ALG))),consqrs(2:end-2));
    consqrs(2:end-2) = consqrs(2:end-2) + lag - WIN_ALG - 1;
    % Put all detectors on same sign (max or min) - shift by median lag
    if flag
        [~,lag]=arrayfun(@(x) max(signal(x-WIN_ALG:x+WIN_ALG)),consqrs(3:end-2));
    else
        [~,lag]=arrayfun(@(x) min(signal(x-WIN_ALG:x+WIN_ALG)),consqrs(3:end-2));
    end
    qrs{5} = consqrs(3:end-2) + lag - WIN_ALG - 1;
catch
    disp('Consensus failed.')
    qrs{5} = qrs{3};
end

% Remove border detections
qrs = cellfun(@(x) x(x>MIRR&x<LEN-MIRR)-MIRR,qrs,'UniformOutput',false);
signal = signal(MIRR+1:end-MIRR); % just for plotting
ect_qrs = ect_qrs(ect_qrs>MIRR&ect_qrs<(LEN-MIRR)) - MIRR; 


clear lag flag consqrs
%% In case ectopic beats are present (consensus QRS locations is ignored, matched filter assumes)
% try
%     if ~isempty(ect_qrs)
%         % Remove ectopic beats
%         cons = qrs{4};
%         [~,dist] = dsearchn(cons,ect_qrs);
%         insbeats = ect_qrs(dist>REF_WIN); % inserting these beats
%         
%         cons = sort([cons; insbeats]);
%         cons(arrayfun(@(x) find(cons==x),insbeats)) = NaN; % insert NaN on missing beats
%         cons = round(inpaint_nans(cons)); % Interpolate with simple spline over missing beats
%         cons(cons<1|cons>length(signal)) = [];
%         cons = sort(cons);
%         cons(diff(cons)<REF_WIN) = [];
%         qrs{6} = cons;
%         
%         %    % visualise
% %             plot(signal)
% %             hold on
% %             plot(qrs{4},2.*ones(size(qrs{4})),'ob')
% %             plot(ect_qrs,2.*ones(size(ect_qrs)),'xr')
% %             plot(qrs{6},3.*ones(size(qrs{6})),'md')
% %             legend('signal','matchedf','ectopic','interpolated')
%         %     close
%         
%     else
%         qrs{6} = qrs{5};
%     end
    
% catch
%     warning('Figuring out ectopic failed.')
%     qrs{6} = qrs{5};
%     ect_qrs = [];
% end


%% Generating some features

% Feature proportion of ectopic beats
feat_ect = numel(ect_qrs)/(numel(qrs{4})+numel(ect_qrs));

% Binary feature, could not generate templates (maybe noisy?)
feat_tpl = matchedf;

% Amplitude around QRS complex
normsig = signal./median(signal(qrs{end})); % normalized amplitude
feat_amp = var(normsig(qrs{end})); % QRS variations in amplitude
feat_amp2 = std(normsig(qrs{end})); % QRS variations in amplitude
feat_amp3 = mean(diff(normsig(qrs{end}))); % QRS variations in amplitude

feats = [feat_tpl feat_ect feat_amp feat_amp2 feat_amp3];

%% Plots for sanity check
% subplot(2,1,1)
% plot(signal,'color',[0.7 0.7 0.7])
% hold on
% plot(qrs{1},signal(qrs{1}),'sg')
% plot(qrs{2},signal(qrs{2}),'xb')
% plot(qrs{3},signal(qrs{3}),'or')
% plot(qrs{4},signal(qrs{4}),'dy')
% plot(qrs{5},1.3*median(signal(qrs{5}))*ones(size(qrs{5})),'dm')
% legend('signal','gqrs','jqrs','maxsearch','matchedfilt','kde consensus')
% subplot(2,1,2)
% plot(qrs{6}(2:end),diff(qrs{6})*1000/fs)
% ylabel('RR intervals (ms)')
% ylim([250 1300])
% close

end


function det=kde_fusion(qrs,fs,dlength)
% Function uses Kernel density estimation on fusing multiple detections
%
% Input
%    qrs      Array with all detections
%    fs       Sampling frequency
% dlength     Signal length
%
%
qrs = sort(qrs);
w_std = 0.10*fs;    % standard deviation of gaussian kernels [ms]
pt_kernel = round(fs/2);    % half window for kernel function [samples]

%% Calculating Kernel Density Estimation
% preparing annotations
peaks = hist(qrs,1:dlength);

% kde (adding gaussian kernels around detections)
kernel = exp(-(-pt_kernel:pt_kernel).^2./(2*w_std^2));

% calculating kernel density estimate
kde = conv(peaks,kernel,'same');

%% Decision
% Parameters
min_dist = round(0.2*fs);    % minimal distance between consecutive peaks [ms]
th = max(kde)/3;      % threshold for true positives (good measure is number_of_channels/3)

% Finding candidate peaks
wpoints = 1+min_dist:min_dist:dlength; % start points of windows (50% overlap)
wpoints(wpoints>dlength-2*min_dist) = []; % cutting edges
M = arrayfun(@(x) kde(x:x+2*min_dist-1)',wpoints(1:end), ...
    'UniformOutput',false);  % windowing signal (50% overlap)
M = cell2mat(M);
% adding first segment
head = [kde(1:min_dist) zeros(1,min_dist)]';
M = [head M];
% adding last segment
tail = kde((wpoints(end)+2*min_dist):dlength)';
tail = [tail; zeros(2*min_dist-length(tail),1)];
M = [M tail];
[~,idx] = max(M);   % finding maxima
idx = idx+[1 wpoints wpoints(end)+2*min_dist]; % absolute locations
idx(idx < 0) = [];
idx(idx > length(kde)) = [];
i = 1;
while i<=length(idx)
    doubled = (abs(idx-idx(i))<min_dist);
    if sum(doubled) > 1
        [~,idxmax]=max(kde(idx(doubled)));
        idxmax = idx(idxmax + find(doubled,1,'first') - 1);
        idx(doubled) = [];
        idx = [idxmax idx];
        clear doubled idxmax
    end
    i = i+1;
end

% threshold check
idx(kde(idx)<th) = [];
det = sort(idx)';

end

