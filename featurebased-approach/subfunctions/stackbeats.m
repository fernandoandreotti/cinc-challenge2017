function [M,RES] = stackbeats(signal,qrs,T_LENGTH,NB_BINS)
% Stack and wraps beats onto a matrix M
%  RES = time reference to resample from bins to time
%
% --
% ECG classification from single-lead segments using Deep Convolutional Neural 
% Networks and Feature-Based Approaches - December 2017
% 
% Released under the GNU General Public License
%
% Copyright (C) 2017  Fernando Andreotti, Oliver Carr
% University of Oxford, Insitute of Biomedical Engineering, CIBIM Lab - Oxford 2017
% fernando.andreotti@eng.ox.ac.uk
%
% 
% For more information visit: https://github.com/fernandoandreotti/cinc-challenge2017
% 
% Referencing this work
%
% Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). 
% Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect 
% Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).
%
% Last updated : December 2017
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

% Parameter
if size(signal,1) < size(signal,2), signal = signal'; end

phase = FECGx_kf_PhaseCalc(qrs,length(signal));
ini_cycles = find(phase(2:end)<0&phase(1:end-1)>0)+1; % start of cycles
cycle_len = diff(ini_cycles); % distance between cycles
end_cycles = ini_cycles(1:end-1)+cycle_len-1; % start of cycles
meanPhase = linspace(-pi,pi,NB_BINS);
RES =  2.*round((median(cycle_len)+1)/2)-1;
% stacking cycles
cycle = arrayfun(@(x) interp1(phase(ini_cycles(x):end_cycles(x)),...
    signal(ini_cycles(x):end_cycles(x)),meanPhase,'spline'),...
    1:length(ini_cycles)-1,'UniformOutput',0);
M = cell2mat(cycle')';

% re-aligning beats
i = 1;
while i<=size(M,2)
    lag = finddelay(mean(M'),M(:,i)); % finds lag on the beat
    if abs(lag) > T_LENGTH    % only allows 20% shift
        M(:,i) = [];            % otherwise ignore beat
        continue
    end
    if size(M,2)>2 && lag < 0
        M(end-abs(lag):end,i) = 0;
    elseif size(M,2)>2
        M(1:lag,i) = 0;
    end
    M(:,i)=circshift(M(:,i),[-lag,1]);
    i = i+1;
end


end
