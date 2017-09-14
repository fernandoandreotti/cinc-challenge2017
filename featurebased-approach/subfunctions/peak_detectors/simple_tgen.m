function [templates,numcycle,status] = simple_tgen(ecg,qrs,fs,T_LENGTH)
% this function is used to contruct a template ecg based on the location of
% the R-peaks. A series of peaks that match with each other are stacked to
% build a template. This template can then be used for ecg morphological
% analysis or further processing. Note that the qrs location inputed must
% be as precise as possible. This approach for building the template ECG
% seems to be the best of the alternatives that were tested and leaves the
% freedom of having more than one mode (i.e. multiple ECG template can be
% built if there are different cycle morphology such as PVC)  but it is not
% particularly fast.
% The procedure for building the template is:
% 1. create average wrapped template
% 2. identify different modes present
%
% inputs
%   ecg:            the ecg channel(s)
%   qrs:            qrs location [number of samples]
%
% outputs
%   relevantMode:   structure containing cycle, cycleMean and cycleStd
%                   representing how many cycles have been selected to build the stack, the
%                   mean ecg cycle that is built upon these selected cycles and the
%                   standard deviation for each point of the template cycle as an indicator
%                   of the precision of the estimation. *Only the dominant mode is outputted
%                   for this application.*
%   status:         bool, success or failed to extract a dominant mode
%
%

% == manage inputs
if nargin<2; error('ecg_template_build: wrong number of input arguments \n'); end;

if size(ecg,1)>size(ecg,2), ecg = ecg';end

% == constants
T_LENGTH = 2.*round((T_LENGTH+1)/2)-1; % making sure it is odd
WIN = floor(T_LENGTH/2);
extremities = (qrs <= WIN | qrs >= length(ecg)-WIN);        % test if there are peaks on the border that may lead to error
qrs = round(qrs(~extremities));                                % remove extremity peaks


%% Phase wrap to get all within 2*pi
NB_BINS = 250; % number of bins for wrapping
phase = FECGx_kf_PhaseCalc(qrs,length(ecg));
ini_cycles = find(phase(2:end)<0&phase(1:end-1)>0)+1; % start of cycles
cycle_len = diff(ini_cycles); % distance between cycles
end_cycles = ini_cycles(1:end-1)+cycle_len-1; % start of cycles
meanPhase = linspace(-pi,pi,NB_BINS);
% stacking cycles
cycle = arrayfun(@(x) interp1(phase(ini_cycles(x):end_cycles(x)),...
    ecg(1,ini_cycles(x):end_cycles(x)),meanPhase,'spline'),...
    1:length(ini_cycles)-1,'UniformOutput',0);
M = cell2mat(cycle')';

% re-aligning beats
i = 1;
while i<=size(M,2)
    lag = finddelay(mean(M'),M(:,i)); % finds lag on the beat
    if abs(lag) > 0.2*T_LENGTH    % only allows 20% shift
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

clear cycle idx meanPhase end_cycles cycle_len ini_cycles phase i lag

%% Clustering
Nclus = 5;
M = bsxfun(@times,M,hamming(size(M,1)));
[~, clusters, ~] = fkmeans(M',Nclus);





%% Heuristics decisions on what is what.

NB_CYCLES = size(M,2);
% spit something if no beat is suitablesimple_tgen(ecg,qrs,T_LENGTH,debug)
if NB_CYCLES == 0
    template.avg = ones(T_LENGTH+1,1);
    template.std = ones(T_LENGTH+1,1);
    return
end
clear N idx lag i

% = Generating final templates
status = true;
templates = cell(length(relevantMode),1);
for i = 1:length(relevantMode)
    templates{i} = circshift(Mode{relevantModeInd(i)}.cycleMean',[-round(T_LENGTH/10),0])';
    numcycle(i) = Mode{relevantModeInd(i)}.NbCycles;
end

% = Check if templates are TOO similar, case affirmative, merge those.
% This may fail if correlations get too weird for several beats
if length(templates)>1 && length(templates) < 5
    xcorel = zeros(length(templates));
    for i = 1:length(templates)
        for j = i+1:length(templates)
            corel = corrcoef(templates{i},templates{j});
            xcorel(i,j) = corel(1,2);
        end
    end
    [i,j]= find(xcorel > 0.6);
    mergeidx = unique([i;j]);
    if ~isempty(mergeidx)
        templates{mergeidx(1)} = mean(cell2mat(templates(mergeidx)'),2);
        numcycle(mergeidx(1)) = sum(numcycle(mergeidx));
        numcycle(mergeidx(2:end)) = [];
        templates(mergeidx(2:end)) = [];
    end
end
    
    %
    %
    %
    
end
