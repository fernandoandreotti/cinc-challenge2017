function sqi = ksqi(signal)
%kSQI Kurtosis SQI
% 
% Returns the kurtosis of a signal
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
%   sqi:            resulting kSQI for segment
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

sqi=kurtosis(signal);

end

