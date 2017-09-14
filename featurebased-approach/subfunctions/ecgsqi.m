function feats = ecgsqi(signal,qrs,fs)
% This function calculates multiple SQIs for electrocardiogram (ECG) signals.
%
% Input:
%     signal            ECG signal (function only supports vectors)
%     fs                sampling frequency (in Hz)
%
% Output:
%     sqi               Resulting SQI for ABP signal
%    qrs_out            QRS samplestamps
%
%
% --
% NIBP estimation
% Released under the GNU General Public License
%
% Copyright (C) 2017  Fernando Andreotti
% University of Oxford, Computational Intelligence in BIomedical Monitoring (CIBIM)
% fernando.andreotti@eng.ox.ac.uk
%
% For further information please visit: $WEBSITE
%
% Referencing this work
%
% $SOME_PUBLICATION
%
% Last updated : 06/03/2017
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

%% Parameters
WIN_ACCEPT = 0.10;    % acceptance interval for FP in QRS detection (in s)
WIN_QRS = 0.1;         % window used to delimit QRS complexes (in s)
% WIN = 6*fs;           % use 6 s to calculate SQI
% OLAP = 0.5*fs;            % window overlap
% NUM_SEG = ceil((length(signal)-WIN/2)/OLAP);

% sqi_tmp = NaN(Nsqi,NUM_SEG);
% qrs = [];
% startp = 1;
% endp = WIN;
% runloop = true;
% count = 1;
% while runloop
%     % Exit condition
%     if endp >= length(signal)
%         runloop = false;
%         endp = length(signal);
%     end
%     sig = signal(startp:endp); % chunk of data used on this iteration



%% Individual SQIs

% Temporal SQIs
% feat_flat = flatsqi(signal);  % flatline detection
feat_stdsqi  = stdsqi(signal);   % standard deviation
feat_ksqi  = ksqi(signal);   % standard deviation
feat_ssqi  = ssqi(signal);   % standard deviation

% Frequency bands
feat_psqi = psqi(signal,fs,[15 45],[0 100]);

% Detection-based SQIs
combs = nchoosek(1:length(qrs),2);
combs = num2cell(combs,2);
feat_bsqi = cellfun(@(x) bsqi(qrs{x(1)},qrs{x(2)},WIN_ACCEPT,fs),combs);
feat_rsqi = arrayfun(@(x) rsqi(qrs{x},fs,0.96),1:length(qrs));
feat_csqi = arrayfun(@(x) csqi(signal,qrs{x},fs,WIN_QRS),1:length(qrs));
feat_xsqi = arrayfun(@(x) xsqi(signal,qrs{x},fs,WIN_QRS),1:length(qrs));


feats = [feat_stdsqi, feat_ksqi, feat_ssqi, ...
    feat_psqi, feat_bsqi', feat_rsqi, feat_csqi, feat_xsqi];

feats(isnan(feats)) = 0; % making sure there are no NaNs

%     % Next loop
%     startp = startp + OLAP; % move window
%     endp = startp + WIN -1;
%     count = count +1;
% end

% sqi_tmp(:,all(isnan(sqi_tmp))) = []; % removing empty columns
% sqi = mean(sqi_tmp);
% sqi = reshape(repmat(sqi,OLAP,1),[],1);
% sqi = [repmat(sqi(1),floor(WIN/2),1); sqi; ... % padding borders
%     repmat(sqi(end),floor(WIN/2)-OLAP,1)];



