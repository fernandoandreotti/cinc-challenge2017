function [SigSegments,QRSsegments]=segment_QRS(QRS,signal,fs,window,overlap)

% Function to segment signal in to windows of specified length and overlap

% Inputs:
%           QRS -               vector of QRS detection locations to be
%                               split in to windows (seconds)
%           signal -            ECG signal to be split in to windows (seconds)
%           fs -                sampling frequency of signal
%           window -            required window length of signal (seconds)
%           overlap -           window overlap (0<=overlap<1)
%
% Output:
%           QRSsegments -       structure of QRS detections for each window
%           SigSegments -       structure of signal segmented in to windows

signal_length=length(signal)/fs;
wind_samp=window*fs;
QRS=QRS./fs;

% Amount window moves by
a=window-(overlap*window);

% Number of windows
num_win=floor((signal_length-window)/a)+1;

% Window start times
start_times=0:a:(num_win-1)*a;

if isempty(start_times)
    start_times  = 0;
end

% If a section is missed at the end (greater than X seconds)
% Add one window finishing at end time
X=2;
if signal_length-(start_times(end)+window)>X
    start_times=[start_times,signal_length-window];
end

% Find indices of QRS series at start times and end times
QRSsegments = arrayfun(@(x) QRS((QRS>x)&(QRS<(x+window)))-x,start_times,'UniformOutput',0);

% Find signal segments
SigSegments = arrayfun(@(x) signal(x:min(x+wind_samp,length(signal))),round(start_times*fs)+1,'UniformOutput',0);


