function sqi = xsqi(signal,qrs,fs,win)
%xSQI Extravagance SQI
% 
% Despite the fancy name, this function does some pretty boring
% calculations, while attempting to describe how different a QRS complex is
% from the rest of the signal. This is particularly important for FECG
% signals, which are often buried into noise.
% 
% Input:
%   signal:         single channel (F)ECG [1xN double]
%   qrs:            list with (F)QRS locations [1xNp double]
%   fs:             signal sampling frequency [Hz]
%   win:            half of the window length around (F)QRS complex [ms],
%                   same window is used to noise area
% 
% Output:
%   sqi:            resulting xSQI for segment
% 
% Fetal Extraction Toolbox, version 1.0, February 2014
% Released under the GNU General Public License
%
% Copyright (C) 2014 Fernando Andreotti4
% Dresden University of Technology, Institute of Biomedical Engineering
% fernando.andreotti@mailbox.tu-dresden.de
%
% Last updated : 30-06-2016
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version.
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.


%% Generate a template
% removing extremities detections
if size(qrs,2) > size(qrs,1); qrs = qrs';end
if size(signal,2) > size(signal,1); signal = signal';end

win =  2.*round(win*fs/2); % rounding to nearest even number
hwin = 0.5*win;
extremities = (qrs <= round(1.5*win) | qrs >= length(signal)-round(1.5*win));        % test if there are peaks on the border that may lead to error
qrs = round(qrs(~extremities));                                    % remove extremity peaks
if length(qrs) <3
    disp('xsqi: skipping due to low number of beats available')
    sqi = 0;
    return
end
% Stacking cycles
M = arrayfun(@(x) signal(x-hwin:x+hwin)'.^2,qrs,'UniformOutput',false);    % creates beat matrix
M = cell2mat(M);                                                        % converting cell output to array form (matrix is 2*width+1 x
N = arrayfun(@(x) signal([(x-hwin-win):(x-hwin) (x+hwin):(x+hwin+win)])'.^2,qrs,'UniformOutput',false);    % creates a surrounding matrix
N = cell2mat(N);                                                        % converting cell output to array form (matrix is 2*width+1 x

%% Check power
Psrd = median(median(N.^2)); % Power of sorroundings
Ppeak=median(median(M.^2)); % Power of peaks
sqi=Ppeak/(Psrd+Ppeak); % percentage of power that the peaks represent



end

