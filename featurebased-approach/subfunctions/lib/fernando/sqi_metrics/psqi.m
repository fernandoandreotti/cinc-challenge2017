function sqi = psqi(signal,fs,btest,btot)
%pSQI Power of QRS SQI
%
% Returns the relative power on band P(5-20Hz)/P(5-45Hz). Operates in 1D or
% 2D vectors for some speeding up.
%
% Reference:
% Li, Q., Mark, R. G., Clifford, G. D., & Li. (2008). Robust heart rate
% estimation from multiple asynchronous noisy sources using signal quality
% indices and a Kalman filter. Physiol. Meas., 29(1), 15–32.
% http://doi.org/10.1088/0967-3334/29/1/002
%
% Input:
%   signal:         single channel (F)ECG [1xN double]
%
% Output:
%   sqi:            resulting sSQI for segment
%
% Fetal Extraction Toolbox, version 1.0, February 2014
% Released under the GNU General Public License
%
% Copyright (C) 2014 Fernando Andreotti
% Dresden University of Technology, Institute of Biomedical Engineering
% fernando.andreotti@mailbox.tu-dresden.de
%
% Last updated : 09-03-2014
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

signal(isnan(signal)) = 0;

xdft = fft(detrend(signal),[],1);
xdft = xdft(1:floor(size(signal,1)/2+1),:);
xdft(2:end-1,:) = 2*xdft(2:end-1,:);
psdest = 1/(size(signal,1)*fs)*abs(xdft).^2;
freq = 0:fs/size(signal,1):fs/2;

% plot(freq,psdest);
% xlabel('Hz');
% grid on;
% title('Single-Sided Amplitude Spectrum of S(t)')
% xlabel('f (Hz)')
% ylabel('|P1(f)|')


if nargin < 3
    btest = [5 15];
    btot = [5 40];
end

pband = sum(psdest(freq>=btest(1)&freq<=btest(2),:));
ptot = sum(psdest(freq>=btot(1)&freq<=btot(2),:));
sqi = 1-(pband./ptot);


end



