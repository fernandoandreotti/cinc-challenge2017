function feat=HRV_features(ecg,qrs,fs)
% This function obtains a series of HRV features from ECG segment.
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



if size(qrs,1) > size(qrs,2); qrs = qrs';end % check column or row vector

% HRV features
hrv_now=[qrs(2:end);diff(qrs)];
HRV=get_hrv(hrv_now');
AFEv = comput_AFEv(hrv_now(2,:)'); % sample code feature
hrv_all=[AFEv struct2array(HRV)];



%%
% Wavelet features
d = designfilt('bandpassiir','FilterOrder',10, ...
    'PassbandFrequency1',0.5,'PassbandFrequency2',50, ...
    'PassbandRipple',1.5, ...
    'StopbandAttenuation1',40,'StopbandAttenuation2',40, ...
    'SampleRate',fs);

y=filtfilt(d,ecg);

N=length(y);

L = nextpow2(N);
add0=2^L-N;
pad1=floor(add0/2);
pad2=add0-pad1;
y_now=[zeros(pad1,1);y;zeros(pad2,1)];

[swa,swd] = swt(y_now,L,'db5');

for j=1:L
    [pxx1,f1]=pwelch(swa(j,:),[],[],[],fs);
    [pxx2,f2]=pwelch(swd(j,:),[],[],[],fs);
    
    [~,ind1]=min(abs(f1-4));
    [~,ind2]=min(abs(f1-9));
    
    PpeakSWA=max(pxx1(ind1:ind2));
    PpeakSWD=max(pxx2(ind1:ind2));
    
    Q1=trapz(f1(ind1:ind2),pxx1(ind1:ind2));
    Q2=trapz(f2(ind1:ind2),pxx2(ind1:ind2));
    
    PavSWA=0.2*Q1;
    PavSWD=0.2*Q2;
    
    sSWA(j)=PpeakSWA/PavSWA;
    sSWD(j)=PpeakSWD/PavSWD;
    
end
feat=[hrv_all, sSWA(1:10),sSWD(1:10)];
