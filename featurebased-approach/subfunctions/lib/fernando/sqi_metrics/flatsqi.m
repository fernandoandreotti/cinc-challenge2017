function sqi = flatsqi(signal)
%flatSQI Flatline SQI
% 
% 
% Input:
%   signal:         single channel (F)ECG [1xN double]
%  MIN_AMP:         if the median of the filtered ECG is inferior to MINAMP 
%                   then it is likely to be a flatline note the importance of 
%                   the units here for the ECG (mV) 
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

MIN_AMP = 0.1; 
% == Flatline detection
if (sum(abs(signal-median(signal))>MIN_AMP)/length(signal))<0.05
    % this is a flat line
    sqi = 0;
else
    sqi = 1;
end
% if 20% of the samples (or more) have an absolute amplitude which is higher
% than MIN_AMP then we are good to go.