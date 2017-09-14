function sqi = csqi(signal,qrs,fs,win)
%cSQI Conformity SQI
% 
% Takes the median correlation coefficient between a template beat and each
% individual beat on a chunk of signal
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
% Copyright (C) 2014 Fernando Andreotti
% Dresden University of Technology, Institute of Biomedical Engineering
% fernando.andreotti@mailbox.tu-dresden.de
%
% Last updated : 30-06-2016
%
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
if size(qrs,1) > size(qrs,2); qrs = qrs';end % fixing position
if size(signal,1) > size(signal,2); signal = signal';end % fixing position

win = ceil(win*fs); % convert to samples
extremities = (qrs <= win | qrs >= length(signal)-win);        % test if there are peaks on the border that may lead to error
qrs = round(qrs(~extremities));                                    % remove extremity peaks
if length(qrs) <5
    disp('csqi: skipping due to low number of beats available')
    sqi = 0;
    return
end

% Stacking cycles
M = arrayfun(@(x) signal(1,x-win:x+win)',qrs,'UniformOutput',false);    % creates a maternal beat matrix
M = cell2mat(M);                                                        % converting cell output to array form (matrix is 2*width+1 x
avgbeat = median(M,2)';                                                 % generates template from detected QRS

%% Calculate individual corrcoef
corr = zeros(1,size(M,2));
for i=1:size(M,2)
    c = corrcoef(avgbeat,M(:,i));
    corr(i) = c(1,2);
end

%% Median correlation
sqi = mean(corr);
sqi(sqi<0) = 0; % negative correlations are zero

end

