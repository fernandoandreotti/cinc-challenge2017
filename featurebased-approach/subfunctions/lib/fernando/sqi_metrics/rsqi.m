function sqi = rsqi(qrs,fs,CI,debug)
% compute smoothness of hrv or of hr time series given a confidence interval (CI).
% The underlying assumption for using this function is that the more smooth
% the qrs time series is the most likely it is to be a meaningful qrs time series.
%SMI = length(find(abs(hrv_CI)>30));

% inputs
%   qrs:    qrs fiducials (required, in data points number)
%   secDer: use second derivative? (i.e. HRV instead of HR to
%           compute SMI, default: 1)
%   fs:     sampling frequency (default: 1kHz)
%   CI:     confidence interval (default: 0.96)
%   segL:   length of the ecg segment in seconds (default: 60sec)
%
% outputs
%   sqi     percentage of intervals inside CI
%
% References:
% [1] Johnson, A. E. W., Behar, J., Andreotti, F., Clifford, G. D. and Oster, J. (2015).
% Multimodal heart beat detection using signal quality indices, Physiological Measurement
% 36 (2015): 1665-1677.
%
%
%
% Multimodal peak detection using ECG, ABP, PPG or SV
% Johnson, A. E. W., Behar, J., Andreotti, F., Clifford, G. D. and Oster, J.
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

if size(qrs,2) > size(qrs,1); qrs = qrs';end

if length(qrs) < 3, sqi = 0; return; end;

% == manage inputs
if nargin<1; error('rsqi: wrong number of input arguments \n'); end;
if nargin<2; fs = 1000; end;
if nargin<3; CI = 1; end;
if nargin<4; debug = 0; end;
if length(qrs) < 5;
    sqi = 0;
    disp('rSQI: too few qrs detection points')
    return
end

% == core function
%try
% == compute variability
hr = 60./(diff(qrs)/fs);


% rather than looking at the distribution of hr this option is looking at
% the distribution of hrv. This makes more sense because this way
% we are looking into high variation in deltaHR from a measure to the
% following one rather than the variability of absolute value of HR (which
% might be high if the foetus HR is changing significantly)



% now taking the derivative of smoothed hear rate. This will give the
% hrv
hrv = sort(diff(hr));
hrv_N = length(hrv);
% plot(hr); hold on, plot(yi,'r');
% we tolerate some mistakes using a confidence interval
if CI~=1
    CI_sup = ceil(hrv_N*(CI+(1-CI)/2));
    CI_inf = ceil(hrv_N*((1-CI)/2));
    hrv_CI = hrv(CI_inf:CI_sup);
else
    hrv_CI = hrv;
end
% output the std of the hrv
% SMI = std(hrv_CI); % OLD version

% new version (25-08-2013)
SMI = length(find(abs(hrv_CI)>20));
% this looks at the absolute number of outliers in hrv_CI with >
% 30bpm drop or increase from a point to the next.



sqi = 1 - SMI/hrv_N;
if sqi <0
    disp('What')
end

% == plots
if debug
    hist(hrv_CI,40); xlabel('hr or hrv histogram');
    title(['assess regularity in term of hr or hrv, REGULARITY:' SMI]);
    set(findall(gcf,'type','text'),'fontSize',14,'fontWeight','bold');
end

end
