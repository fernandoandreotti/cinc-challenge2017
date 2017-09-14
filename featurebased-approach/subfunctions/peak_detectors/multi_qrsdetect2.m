function qrs=multi_qrsdetect2(signal,fs,fname)


qrs = cell(1,5); % CHANGE ME! Using 6 levels of detection

WIN_ALG = round(0.08*fs);  % 100ms allow re-alignment of 80ms for gqrs
REF_WIN = round(0.17*fs);  % refractory window PT algorithm, no detection should occur here.
MIRR = round(2*fs);        % length to mirror signal at beginning and end to avoid border effects

LEN = length(signal);
signal = [signal(1:MIRR); signal ; signal(LEN-MIRR+1:LEN)];
LEN = LEN + 2*MIRR;


%% P&T algorithm (in windows of 5 seconds - 1 sec overlap)
try
    disp(['Running jqrs ' fname '...'])
    qrs{1} = jqrs(signal,REF_WIN,[],fs,[],[],0);
    [~,lag]=arrayfun(@(x) max(abs(signal(x-WIN_ALG:x+WIN_ALG))),qrs{1}(2:end-1));
    qrs{1}(2:end-1) = qrs{1}(2:end-1) + lag - WIN_ALG - 1;
    disp(['jqrs ran ' fname '... found ' num2str(length((qrs{1})))  ' peaks'])
catch
    warning('Pan Tompkins failed.')
    qrs{1} = [];
end
clear lag


%% MaxSearch (mQRS)
try
    disp(['Running maxsearch ' fname '...'])
    if length(qrs{1})<5
        HR_PARAM = 1.3; % default value
    else
        HR_PARAM = fs./nanmedian(diff(qrs{1}))+0.1;  % estimate rate (in Hz) for MaxSearch
    end    
    qrs{2} = OSET_MaxSearch(signal,HR_PARAM/fs)';
    disp(['maxsearch ran ' fname '... found ' num2str(length((qrs{2})))  ' peaks'])
catch
    warning('MaxSearch failed.')
    qrs{2} = [];
end

%% gQRS
try
    recordName = ['gd_' fname];
    tm = 1/fs:1/fs:LEN/fs;
    wrsamp(tm',signal,recordName,fs,1)
    disp(['Running gqrs ' fname '...'])
    if isunix                 
        system(['gqrs -r ' recordName ' -f 0 -s 0']);
    else
       gqrs(recordName)
    end
    qrs{3} = rdann(recordName,'qrs');        
    disp(['read gqrs output ' fname '...'])
    [~,lag]=arrayfun(@(x) max(abs(signal(x-WIN_ALG:x+WIN_ALG))),qrs{3}(2:end-1));
    qrs{3}(2:end-1) = qrs{3}(2:end-1) + lag - WIN_ALG - 1;
    disp(['wqrs ran ' fname '... found ' num2str(length((qrs{3})))  ' peaks'])
catch
    warning('gqrs failed.')
    delete([recordName '.*'])
    qrs{3} = [];
end
clear lag HR_PARAM qrsmax

%% wqrs detectors
try
    disp(['Running wqrs ' fname '...'])
    if isunix                 
        system(['wqrs -r ' recordName ' -f 0 -s 0']);        
    else
       wqrs(recordName)
    end
    qrs{4} = rdann(recordName,'wqrs');        
    [~,lag]=arrayfun(@(x) max(abs(signal(x-WIN_ALG:x+WIN_ALG))),qrs{4}(2:end-1));
    qrs{4}(2:end-1) = qrs{4}(2:end-1) + lag - WIN_ALG - 1;
    delete([recordName '.*'])
    disp(['wqrs ran ' fname '... found ' num2str(length((qrs{4})))  ' peaks'])
catch
    warning('wqrs failed.')
    delete([recordName '.*'])
    qrs{4} = [];
end
clear lag tm recordName HR_PARAM qrsmax


%% Consensus detection
try
    consqrs = kde_fusion(cell2mat(qrs(1:3)'),fs,length(signal)); % 2x gqrs
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
    disp(['Consensus found ' num2str(length((qrs{5})))  ' peaks'])
catch
    disp('Consensus failed.')
    qrs{5} = qrs{2};
end

% Remove border detections
qrs = cellfun(@(x) x(x>MIRR&x<LEN-MIRR)-MIRR,qrs,'UniformOutput',false);
signal = signal(MIRR+1:end-MIRR); % just for plotting
clear lag flag consqrs

%% Plots for sanity check
% subplot(2,1,1)
% plot(signal,'color',[0.7 0.7 0.7])
% hold on
% plot(qrs{1},signal(qrs{1}),'sg')
% plot(qrs{2},signal(qrs{2}),'xb')
% plot(qrs{3},signal(qrs{3}),'or')
% plot(qrs{4},signal(qrs{4}),'dy')
% plot(qrs{5},1.3*median(signal(qrs{5}))*ones(size(qrs{5})),'dm')
% plot(qrs{6},signal(qrs{6}),'sb')
% legend('signal','gqrs','jqrs','maxsearch','matchedfilt','kde consensus','interp')
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

