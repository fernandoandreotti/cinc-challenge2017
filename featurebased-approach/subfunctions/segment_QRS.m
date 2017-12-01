function [SigSegments,QRSsegments]=segment_QRS(QRS,signal,fs,window,overlap)
% Function to segment signal in to windows of specified length and overlap
%
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
%
%
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


