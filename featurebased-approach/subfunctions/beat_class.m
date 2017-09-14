function [type,beats,beatsuct] = beat_class(ecg,qrs,T_LENGTH)
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
% Dependencies: FECGSYN_phase_wrap.m
%
%

% == manage inputs
if nargin<2; error('ecg_template_build: wrong number of input arguments \n'); end;

if size(ecg,1)>size(ecg,2), ecg = ecg';end

% == constants
% qrs(1) = []; qrs(end) = [];                                % remove extremity peaks
extremities = (qrs <= 2*T_LENGTH | qrs >= length(ecg)-2*T_LENGTH);        % test if there are peaks on the border that may lead to error
qrs = round(qrs(~extremities)); % remove extremity peaks

%% Phase wrap to get all within 2*pi
NB_BINS = 250; % number of bins for wrapping
[M,RES] = stackbeats(ecg,qrs,T_LENGTH,NB_BINS);
    

% beatsuct = median(M')';
% dem = round((length(beatsuct)-2*T_LENGTH-1)/2); 
% beats{1} =  beatsuct(dem+1:end-dem);
% type = ones(length(qrs),1);

%% Clustering
Nclus1 = 5;
Nclus2 = 2;
M = bsxfun(@times,M,hamming(size(M,1)));  % do it twice, it's the
M = bsxfun(@times,M,hamming(size(M,1)));  % magic sauce
M = bsxfun(@times,M,hamming(size(M,1)));  % magic sauce
M = M';
% [~, clusters, ~] = fkmeans(M',Nclus);
rng(1);
[~,clusters,~] = kmeans(M,Nclus1); % may need to provide centroid..
[~,clusters,~] = kmeans(clusters,Nclus2); % may need to provide centroid..
clusters = clusters';

% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% TODO: allow more than two clusters!!!!!!!!!!!!!!!!!!!!
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

corel = corrcoef(clusters(50:200,1),clusters(50:200,2));


%% In case beats are correlated to each other
if corel(1,2) > 0.7 
    type = ones(size(qrs));
    beats{1} = resample(mean([clusters(:,1), clusters(:,2)],2),RES,NB_BINS);    
    dem = (length(beats{1})-2*T_LENGTH-1)/2;   
    beatsuct = beats;
    beats = cellfun(@(x) x(dem+1:end-dem),beats,'UniformOutput',0);
    return;
end

%% In case one cluster has low amplitude

idx = var(clusters)<0.1*var(ecg); % remove clusters with variance less than 10% of signal
if any(idx)
   type = ones(size(qrs));
   beats{1} = resample(clusters(:,~idx),RES,NB_BINS);
   dem = round((length(beats{1})-2*T_LENGTH-1)/2);      
   beatsuct = beats;
   beats = cellfun(@(x) x(dem+1:end-dem),beats,'UniformOutput',0);
   return; 
end


%% Classifying beats

beats{1} = resample(clusters(:,1),RES,NB_BINS);
beats{2} = resample(clusters(:,2),RES,NB_BINS);
beatsuct = beats;
dem = (length(beats{1})-2*T_LENGTH-1)/2;
beats = cellfun(@(x) x(dem+1:end-dem),beats,'UniformOutput',0);
    
for i = 1:length(qrs)
    cor = corrcoef(ecg(qrs(i)-T_LENGTH:qrs(i)+T_LENGTH),beats{1});
    corel(1,i) = cor(1,2);
    cor = corrcoef(ecg(qrs(i)-T_LENGTH:qrs(i)+T_LENGTH),beats{2});
    corel(2,i) = cor(1,2);
end
[~,type]=max(corel);

if sum(type==2)>sum(type==1)
    type(type==2) = 3;
    type(type==1) = 2;
    type(type==3) = 2;
end

if all(type==2)
    type = ones(size(type));
end
type = type';
    
end


