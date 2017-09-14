function [sqi,t]=get_sqi(qrs,signal,fs)

%% SQI Windows
windowL=5; % Window size in seconds
windShift=1; % Window shift in seconds

sigflip=flipud(signal);
extsig=[sigflip(end-(windowL*fs/2):end);signal;sigflip(1:windowL*fs)];

for j=1:6
    QRS_start{j}=qrs{j}(qrs{j}<length(sigflip(end-(windowL*fs/2):end)));
    QRS_end{j}=qrs{j}(qrs{j}>(length(signal)-length(sigflip(1:windowL*fs))));
    qrs_now{j}=[flipud(-QRS_start{j}+1);qrs{j};flipud(2*length(signal)-QRS_end{j}+1)]+length(sigflip(end-(windowL*fs/2):end));
end

time=(1:length(extsig))./fs;

time1=0;
for w=1:ceil(length(signal)/(fs*windShift))+1 % Cycle through all 5 second windows
    time2=time1+windowL;
    [~,ind1]=min(abs(time-time1));
    [~,ind2]=min(abs(time-time2));
    sig=extsig(ind1:ind2);
    
    t(w)=time(ind1)+windowL/2; % Get time of current window
    
    QRS_now=qrs_now;        % Get QRS detections in current window
    for i=1:6
        qrs_temp=qrs_now{i}(qrs_now{i}<ind2);
        QRS_now{i}=qrs_now{i}(qrs_temp>ind1);
    end
    qrs_in=cellfun(@(x) x-ind1+1,QRS_now,'UniformOutput',false);
    feats = ecgsqi(sig,qrs_in,fs);
    
    normsig = sig./median(sig(qrs_in{6})); % normalized amplitude
    feat_amp = std(normsig(qrs_in{6}));
    
    % Hilbert envelope
    y = hilbert(extsig);
    env = abs(y);
    fsig = filter(ones(100,1),1,env);
    sqihilb = normpdf(median(fsig(ind1:ind2)),median(fsig),20)*sqrt(2*pi)*20;
    
    
    feats=[feats,feat_amp,sqihilb];
    %         feats(2:4)=[];
    sqi(w,:)=feats;
    time1=time1+windShift;
end
t=t-length(sigflip(end-(windowL*fs/2):end))/fs;