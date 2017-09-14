%% Phase Calculation
% Generates the phase signal for Kalman Filtering
% Inputs
% peaks             QRS peak locations
% length            Length of data for phase generation
% 
% 
% Fetal Extraction Toolbox, version 1.0, February 2014
% Released under the GNU General Public License
%
% Copyright (C) 2014  Fernando Andreotti
% Dresden University of Technology, Institute of Biomedical Engineering
% fernando.andreotti@mailbox.tu-dresden.de
%
% Last updated : 24-07-2014
%
% Based on: Synthetic ECG model error
% Open Source ECG Toolbox, version 2.0, March 2008
% Released under the GNU General Public License
% Copyright (C) 2008  Reza Sameni
% Sharif University of Technology, Tehran, Iran -- LIS-INPG, Grenoble, France
% reza.sameni@gmail.com

% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version.
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.

% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the
% Free Software Foundation; either version 2 of the License, or (at your
% option) any later version.
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.
%
function phase = FECGx_kf_PhaseCalc(peaks,lengthx)
% Based on Sameni's method for phase calculation
phase = zeros(1,lengthx);
m = diff(peaks);            % gets distance between peaks
% first interval
% dealing with borders (first and last peaks may not be full waves)
% uses second interval as reference
L = peaks(1);   %length of first interval
if isempty(m) % only ONE peak was detected
    phase(1:lengthx) = linspace(-2*pi,2*pi,lengthx);
else
    phase(1:L) = linspace(2*pi-L*2*pi/m(1),2*pi,L);
    % beats in the middle
    for i = 1:length(peaks)-1;  % generate phases between 0 and 2pi for almos all peaks
        phase(peaks(i):peaks(i+1)) = linspace(0,2*pi,m(i)+1);
    end                                         % 2pi is overlapped by 0 on every loop
    % last interval
    % uses second last interval as reference
    L = length(phase)-peaks(end);   %length of last interval
    phase(peaks(end):end) = linspace(0,L*2*pi/m(end),L+1);
end
phase = mod(phase,2*pi);
phase(find(phase>pi)) = phase(find(phase>pi))- 2*pi;