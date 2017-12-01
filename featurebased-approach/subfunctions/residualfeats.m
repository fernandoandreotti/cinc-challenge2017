function feats = residualfeats(signal,fs,qrs)
% This function derives features out of QRS cancelled ECG signals, aiming at the atrial information.
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

feats = zeros(1,5);
signal = signal';

if length(qrs) > 5
    residual = FECGSYN_ts_extraction(qrs,signal,'TS-CERUTTI',0,5,2,fs);
else
    return
end

try
    % Cross-correlation
    R=corrcoef(signal,residual);
    feats(1) = 1 - R(1,2);
    
    % Spectral coherence
    [Pmf,f]=mscohere(signal,residual,[],[],1024,fs);
    feats(2)=1-mean(Pmf(f>3&f<30));
    
    feats(3) = psqi(residual',fs);
    
    % Fundamental frequency on spectrum against rest
    feats(4)=mpsqi1(residual',fs);
    
    % Test for randomness
    [h,p,R] = white_test(residual', 1, rand(1e3,1));
    feats(5) = 1-p;
catch
    disp('Residuals failed!')
end

end

function [h, p_value, R] = white_test(x, maxlag, alpha)
% tests against the null hyptothesis of whiteness
% see http://dsp.stackexchange.com/questions/7678/determining-the-whiteness-of-noise for details
% demo:
% % white:
% >> [h,p,R]=white_test(((filter([1], [1], rand(1e3,1)))))
% >> h = 0, p =1, R = 455
% % non white:
% >> [h,p,R]=white_test(((filter([1 .3], [.4 0.3], rand(1e3,1)))))
% >> h = 1, p = 0, R = 2e3
%
% Copyright (c) 2013, Hanan Shteingart
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
% * Redistributions of source code must retain the above copyright
% notice, this list of conditions and the following disclaimer.
% * Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in
% the documentation and/or other materials provided with the distribution
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

N = length(x);
x = x-mean(x);
if ~exist('m','var')
    maxlag = N-1;
end
if ~exist('alpha','var')
    alpha = 0.05;
end
[r, lag] = xcorr(x, maxlag, 'biased');
R = N/r(lag==0)^2*sum(r(lag > 0).^2);
p_value = 1-chi2cdf(R, maxlag);
T = chi2inv(1-alpha, maxlag);
h =  R > T;
end
