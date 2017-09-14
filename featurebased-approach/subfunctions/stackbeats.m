function [M,RES] = stackbeats(signal,qrs,T_LENGTH,NB_BINS)
% Stack and wraps beats onto a matrix M
%  RES = time reference to resample from bins to time
%
%

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