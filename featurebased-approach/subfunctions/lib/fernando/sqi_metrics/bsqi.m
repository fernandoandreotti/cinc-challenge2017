function [ F1, IndMatch ] = bsqi(qrs1,qrs2,win,fs)
%BSQI_MATLAB Calculate bSQI of two inputs
%
% Input:
%  qrs1:          QRS annotations algorithm 1 (reference)
%  qrs2:          QRS annotations algorithm 2 (test)
%  win:           Acceptance interval for TP detection (in s)
%  fs:            Sampling frequency (in Hz)
%
%
% References
%
% [1] Johnson, A. E. W., Behar, J., Andreotti, F., Clifford, G. D. and Oster, J. (2015).
% Multimodal heart beat detection using signal quality indices, Physiological Measurement
% 36 (2015): 1665-1677.
% [2] Johnson, A. E. W., Behar, J., Andreotti, F., Clifford, G. D. and Oster, J. (2014).
% R-peak estimation using multimodal lead switching, Computing in Cardiology Conference
% (CinC), 2014, Vol. 41, pp. 281-284.
%
% [3] Behar, Joachim, et al. "ECG signal quality during arrhythmia and its
% application to false alarm reduction." Biomedical Engineering, IEEE Transactions on 60.6 (2013): 1660-1666.
%
% [4] Li, Qiao, Roger G. Mark, and Gari D. Clifford. "Robust heart rate estimation from multiple asynchronous noisy
% sources using signal quality indices and a Kalman filter." Physiological measurement 29.1 (2008): 15.
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
%

% == managing inputs
if nargin<3; win=0.05; end;
if nargin<4; fs=250; end;
if size(qrs1,2) > size(qrs1,1); qrs1 = qrs1';end
if size(qrs2,2) > size(qrs2,1); qrs2 = qrs2';end
if (length(qrs1) < 3)||(length(qrs2) < 3) 
    F1 = 0;
    disp('bSQI: too few qrs detection points')
    return
end

win = win * fs;

NB_REF  = length(qrs1);
NB_TEST = length(qrs2);
% == core function
[IndMatch,Dist] = dsearchn(qrs1,qrs2);         % closest ref for each point in test qrs
IndMatchInWindow = IndMatch(Dist<win);         % keep only the ones within a certain window
NB_MATCH_UNIQUE = length(unique(IndMatchInWindow)); % how many unique matching
TP = NB_MATCH_UNIQUE;                               % number of identified ref QRS
FN = NB_REF-TP;                                     % number of missed ref QRS
FP = NB_TEST-TP;                                    % how many extra detection?
Se  = TP/(TP+FN);
PPV = TP/(FP+TP);
if (Se == 0)&&(PPV == 0); 
    F1 = 0; 
else
    F1 = 2*Se*PPV/(Se+PPV);                             % accuracy measure    
end

end
