% peaks = OSET_MaxSearch(x,f,flag),
% R-peak detector based on max search
%
% inputs:
% signal: vector of input data
% ff: approximate signal beat-rate in Hertz, normalized by the sampling frequency
% flag: search for positive (flag=1) or negative (flag=0) peaks. By default
% the maximum absolute value of the signal, determines the peak sign.
%
% output:
% peaks: vector of R-peak impulse train
%
% Notes:
% - The R-peaks are found from a peak search in windows of length N; where
% N corresponds to the R-peak period calculated from the given f. R-peaks
% with periods smaller than N/2 or greater than N are not detected.
% - The signal baseline wander is recommended to be removed before the
% R-peak detection
%
%
% Open Source signal Toolbox, version 1.0, November 2006
% Released under the GNU General Public License
% Copyright (C) 2006  Reza Sameni
% Sharif University of Technology, Tehran, Iran -- GIPSA-Lab, INPG, Grenoble, France
% reza.sameni@gmail.com

% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version.
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.
%
% (minor modifications by Fernando Andreotti, October 2013)
% log:     - Allowed multi-channel detection by looping through channels
%          - Made selection of maxima/minima more robust
function peaks = OSET_MaxSearch(signal,ff,varargin)

if size(signal,1) > size(signal,2)
    signal = signal';
end


th = .5;
rng = floor(th/ff);

% By choosing median of 5% of the data length makes flag choice more robust.
% modification by Andreotti
segs = reshape(signal(1:end-mod(length(signal),rng)),rng,[]);
segs = sort(segs,'ascend');

ymax = median(median(segs((end-floor(0.05*rng):end),:)));
ymin = median(median(segs(1:floor(0.05*rng),:)));
flag = ymax > abs(ymin);  % check if 5% data positive or negative
if ~flag
    signal = -signal;    
    clear ymin x y flag
end % always search for maxima

% loops through every channel
x = signal;
N = length(x);
peaks = zeros(1,N);

for j = 1:N,
    %         index = max(j-rng,1):min(j+rng,N);
    if(j>rng && j<N-rng)
        index = j-rng:j+rng;
    elseif(j>rng)
        index = N-2*rng:N;
    else
        index = 1:2*rng;
    end
    
    if(max(x(index))==x(j))
        peaks(j) = 1;
    end
end
% remove fake peaks
I = find(peaks);
d = diff(I);
% z = find(d<rng);
peaks(I(d<rng))=0;

peaks = find(peaks);


% Getting read of peaks with too low amplitude
segs = reshape(abs(signal(1:end-mod(length(signal),rng))),rng,[]);
segs = sort(segs,'ascend');
ymin = median(median(segs(1:floor(0.5*rng),:))); % if lower than the half
peaks(abs(signal(peaks)) < ymin) = []; % remove peaks with little amplitude


