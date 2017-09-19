%CALC_LZ_COMPLEXITY Lempel-Ziv measure of binary sequence complexity. 
%   This function calculates the complexity of a finite binary sequence,
%   according to the algorithm published by Abraham Lempel and Jacob Ziv in
%   the paper "On the Complexity of Finite Sequences", published in 
%   "IEEE Transactions on Information Theory", Vol. IT-22, no. 1, January
%   1976.  From that perspective, the algorithm could be referred to as 
%   "LZ76".
%   
%   Usage: [C, H] = calc_lz_complexity(S, type, normalize)
%
%   INPUTS:
%   
%   S: 
%   A vector consisting of a binary sequence whose complexity is to be
%   analyzed and calculated.  Numeric values will be converted to logical
%   values depending on whether (0) or not (1) they are equal to 0.
%
%   type: 
%   The type of complexity to evaluate as a string, which is one of:
%       - 'exhaustive': complexity measurement is based on decomposing S 
%       into an exhaustive production process.
%       - 'primitive': complexity measurement is based on decomposing S 
%       into a primitive production process.
%   Exhaustive complexity can be considered a lower limit of the complexity
%   measurement approach proposed in LZ76, and primitive complexity an
%   upper limit.
%
%   normalize:
%   A logical value (true or false), used to specify whether or not the 
%   complexity value returned is normalized or not.  
%   Where normalization is applied, the normalized complexity is 
%   calculated from the un-normalized complexity, C_raw, as:
%       C = C_raw / (n / log2(n))
%   where n is the length of the sequence S.
%
%   OUTPUTS:
%
%   C:
%   The Lempel-Ziv complexity value of the sequence S.
%
%   H:
%   A cell array consisting of the history components that were found in
%   the sequence S, whilst calculating C.  Each element in H consists of a
%   vector of logical values (true, false), and represents
%   a history component.
%
%   gs:
%   A vector containing the corresponding eigenfunction that was calculated
%   which corresponds with S.
%
%
%
%   Author: Quang Thai (qlthai@gmail.com)
%   Copyright (C) Quang Thai 2012
%
%
% Copyright (c) 2012, Quang Thai
%All rights reserved.
%
%Redistribution and use in source and binary forms, with or without
%modification, are permitted provided that the following conditions are
%met:
%
%    * Redistributions of source code must retain the above copyright
%      notice, this list of conditions and the following disclaimer.
%    * Redistributions in binary form must reproduce the above copyright
%      notice, this list of conditions and the following disclaimer in
%      the documentation and/or other materials provided with the distribution
%
%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%POSSIBILITY OF SUCH DAMAGE.



function [C, H, gs] = calc_lz_complexity(S, type, normalize)


%% Some parameter-checking.

% Make sure S is a vector.
if ~isvector(S)
    error('''S'' must be a vector');
end

% Make sure 'normalize' is a scalar.
if ~isscalar(normalize)
    error('''normalize'' must be a scalar');
end

% Make sure 'type' is valid.
if ~(strcmpi(type, 'exhaustive') || strcmpi(type, 'primitive'))
    error(['''type'' parameter is not valid, must be either ' ...
        '''exhaustive'' or ''primitive''']);
end



%% Some parameter 'conditioning'.
S = logical(S);
normalize = logical(normalize);



%% ANALYSIS

% NOTE: Many of these comments will refer to the paper "On the Complexity
% of Finite Sequences" by Lempel and Ziv, so to follow this code, it may 
% be useful to have the manuscript in front of you!



% Allocate memory for eigenfunction (vector of eigenvalues).
% The first value of this vector corresponds with gs(0), and is always
% equal to 0.
% Please note that, since MATLAB array indices start at 1, gs(n) in MATLAB
% actually holds gs(n-1) as defined in the paper.
n = length(S);
gs = zeros(1, n + 1);
gs(1) = 0;  % gs(0) = 0 from the paper





% The approach we will use to find the eigenfunction values at each
% successive prefix of S is as follows:
% - We wish to find gs(n), where 1 <= n <= l(S) (l(S) = length of S)
% - Lemma 4 says:
%       k(S(1,n-1)) <= k(S(1,n))
%           equivalently
%       gs(n-1) <= gs(n)
%   In other words, the eigenfunction is a non-decreasing function of n.
% - Theorem 6 provides the expression that defines the eigenvocabulary of
%   a sequence:
%       e(S(1,n)) = {S(i,n) | 1 <= i <= k(S(1,n))}
%           equivalently
%       e(S(1,n)) = {S(i,n) | 1 <= i <= gs(n)}
%   Note that we do not know what gs(n) is at this point - it's what we're
%   trying to find!!!
% - Remember that the definition of the eigenvocabulary of a sequence S(1,n), 
%   e(S(1,n)), is the subset of the vocabulary of S(1,n) containing words 
%   that are not in the vocabulary of any proper prefix of S(1,n), and the 
%   eigenvalue of S(1,n) is the subset's cardinality: gs(n) = |e(S(1,n))|
%   (p 76, 79)
% - Given this, a corollary to Theorem 6 is:
%       For each S(m,n) | gs(n) < m <= n, S(m,n) is NOT a member of
%       the eigenvocabulary e(S(1,n)).
%       By definition, this means that S(m,n) is in the vocabulary of at
%       least one proper prefix of S(1,n).
% - Also note that from Lemma 1: if a word is in the vocabulary of a
%   sequence S, and S is a proper prefix of S+, then the word is also 
%   in the vocabulary of S+.
% 
% As a result of the above discussion, the algorithm can be expressed in
% pseudocode as follows:
% 
% For a given n, whose corresponding eigenfunction value, gs(n) we wish to 
% find:
% - gs(0) = 0
% - Let m be defined on the interval: gs(n-1) <= m <= n
% - for each m
%       check if S(m,n) is in the vocabulary of S(1,n-1)
%       if it isn't, then gs(n) = m
%       end if
%   end for
%
% An observation: searching linearly along the interval 
% gs(n-1) <= m <= n will tend to favour either very complex sequences 
% (starting from n and working down), or very un-complex sequences
% (starting from gs(n-1) and working up).  This implementation will
% attempt to balance these outcomes by alternately searching from either
% end and working inward - a 'meet-in-the-middle' search.
%
% Note that:
% - When searching from the upper end downwards, we are seeking 
% the value of m such that S(m,n) IS NOT in the vocabulary of S(1,n-1).
% The eigenfunction value is then m.
% - When searching from the lower end upwards, we are seeking the value
% of m such that S(m,n) IS in the vocabulary of S(1,n-1).  The
% eigenfunction value is then m-1, since it is the MAXIMAL value of m
% whereby S(m,n) IS NOT in the vocabulary of S(1,n-1)




%% Calculate eigenfunction, gs(n)

% Convert to string form - aids the searching process!
S_string = binary_seq_to_string(S);
gs(2) = 1;  % By definition.  Remember: gs(2) in MATLAB is actually gs(1)
            % due to the first element of the gs array holding the
            % eigenvalue for n = 0.

for n = 2:length(S)
    
    eigenvalue_found = false;
    
    % The search space gs(n-1) <= m <= n.
    % Remember: gs(n) in MATLAB is actually gs(n-1).
    % Note that we start searching at (gs(n-1) + 1) at the lower end, since
    % if it passes the lower-end search criterion, then we subtract 1
    % to get the eigenvalue.
    idx_list = (gs(n)+1):n;
    for k = 1:ceil(length(idx_list)/2);

        % Check value at upper end of interval
        m_upper = idx_list(end - k + 1);
        if ~numel(strfind(S_string(1:(n-1)), S_string(m_upper:n)))
            % We've found the eigenvalue!
            gs(n+1) = m_upper;    % Remember: 
                                  % gs(n+1) in MATLAB is actually gs(n)
            eigenvalue_found = true;
            break;
        end 
        
        % Check value at lower end of interval.
        %
        % Note that the search at this end is slightly more complicated, 
        % in the sense that we have to find the first value of m where the
        % substring is FOUND, and then subtract 1.  However, this is
        % complicated by the 'meet-in-the-middle' search adopted, as
        % described below...
        m_lower = idx_list(k);
        if numel(strfind(S_string(1:(n-1)), S_string(m_lower:n)))
            % We've found the eigenvalue!
            gs(n+1) = m_lower-1;    % Remember: 
                                    % gs(n+1) in MATLAB is actually gs(n)
            eigenvalue_found = true;
            break;
        elseif (m_upper == m_lower + 1)
            % If we've made it here, then we know that:
            % - The search for substring S(m,n) from the upper end had a
            %   FOUND result
            % - The search for substring S(m,n) from the lower end had a 
            %   NOT FOUND result
            % - The value of m used in the upper end search is one more
            %   than the value of m used in this lower end search
            %
            % However, when searching from the lower end, we need a FOUND
            % result and then subtract 1 from the corresponding m.
            % The problem with this 'meet-in-the-middle' searching is that
            % it's possible that the actual eigenfunction value actually
            % does occur in the middle, such that the loop would terminate
            % before the lower-end search can reach a FOUND result and the
            % upper-end search can reach a NOT FOUND result.
            %
            % This branch detects precisely this condition, whereby
            % the two searches use adjacent values of m in the middle,
            % the upper-end search has the FOUND result that the lower-end
            % search normally requires, and the lower-end search has the
            % NOT FOUND result that the upper-end search normally requires.
            
            % We've found the eigenvalue!
            gs(n+1) = m_lower;      % Remember: 
                                    % gs(n+1) in MATLAB is actually gs(n)
            eigenvalue_found = true;
            break;
        end
                
    end
    
    if ~eigenvalue_found
        % Raise an error - something is not right!
        error('Internal error: could not find eigenvalue');
    end
    
end





%% Calculate the terminal points for the required production sequence.

% Histories are composed by decomposing the sequence S into the following
% sequence of words:
%       H(S) = S(1,h_1)S(h_1 + 1,h_2)S(h_2 + 1,h_3)...S(h_m-1 + 1,h_m)
% The indices {h_1, h_2, h_3, ..., h_m-1, h_m} that characterise a history
% make up the set of 'terminals'.
%
% Alternatively, for consistency, we will specify the history as:
%       H(S) = ...
%           S(h_0 + 1,h_1)S(h_1 + 1,h_2)S(h_2 + 1,h_3)...S(h_m-1 + 1,h_m)
% Where, by definition, h_0 = 0.



% Efficiency measure: we don't know how long the histories will be (and
% hence, how many terminals we need).  As a result, we will allocate an
% array of length equal to the eigenfunction vector length.  We will also
% keep a 'length' counter, so that we know how much of this array we are
% actually using.  This avoids us using an array that needs to be resized
% iteratively!
% Note that h_i(1) in MATLAB holds h_0, h_i(2) holds h_1, etc., since
% MATLAB array indices must start at 1.
h_i = zeros(1, length(gs));
h_i_length = 1;     % Since h_0 is already present as the first value!


if strcmpi(type, 'exhaustive')
    
    % - From Theorem 8, for an exhaustive history, the terminal points h_i,
    % 1 <= i <= m-1, are defined by:
    %       h_i = min{h | gs(h) > h_m-1}
    % - We know that h_0 = 0, so this definition basically bootstraps our
    % search process, allowing us to find h_1, then h_2, etc.
    
    h_prev = 0;     % Points to h_0 initially
    k = 1;
    while ~isempty(k)
        % Remember that gs(1) in MATLAB holds the value of gs(0).
        % Therefore, the index h_prev needs to be incremented by 1
        % to be used as an index into the gs vector.
        k = find(gs((h_prev+1+1):end) > h_prev, 1);
        
        if ~isempty(k)
            h_i_length = h_i_length + 1;
            
            % Remember that gs(1) in MATLAB holds the value of gs(0).
            % Therefore, the index h_prev needs to be decremented by 1
            % to be used as an index into the original sequence S.
            h_prev = h_prev + k;
            h_i(h_i_length) = h_prev;
        end
    end
    
    % Once we break out of the above loop, we've found all of the
    % exhaustive production components.
else
    
    % Sequence type is 'primitive'
   
    % Find all unique eigenfunction values, where they FIRST occur.

    % - From Theorem 8, for a primitive history, the terminal points h_i, 
    % 1 <= i <= m-1, are defined by:
    %        h_i = min{h | gs(h) > gs(h_i-1)}
    % - From Lemma 4, we know that the eigenfunction, gs(n), is
    % monotonically non-decreasing.
    % - Therefore, the following call to unique() locates the first
    % occurrance of each unique eigenfunction value, as well as the values
    % of n where the eigenfunction increases from the previous value.
    % Hence, this is also an indicator for the terminal points h_i.

    [~, n] = unique(gs, 'first');

    % The terminals h_i, 1 <= i <= m-1, is ultimately obtained from n by 
    % subtracting 1 from each value (since gs(1) in MATLAB actually
    % corresponds with gs(0) in the paper)
    h_i_length = length(n);
    h_i(1:h_i_length) = n - 1;
end

% Now we have to deal with the final production component - which may or
% may not be exhaustive or primitive, but can still be a part of an
% exhaustive or primitive process.
%
% If the last component is not exhaustive or primitive, we add it here
% explicitly.
%
% - From Theorem 8, for a primitive history, this simply enforces
% the requirement that:
%       h_m = l(S)
if h_i(h_i_length) ~= length(S)
    h_i_length = h_i_length + 1;
    h_i(h_i_length) = length(S);
end

% Some final sanity checks - as indicated by Theorem 8.
% Raise an error if these checks fail!
% Also remember that gs(1) in the MATLAB code corresponds with gs(0).
if strcmpi(type, 'exhaustive')
    % Theorem 8 - check that gs(h_m - 1) <= h_m-1
    if gs(h_i(h_i_length) - 1 + 1) > h_i(h_i_length-1)
        error(['Check failed for exhaustive sequence: ' ...
            'Require: gs(h_m - 1) <= h_m-1']);
    end
else
    % Sequence type is 'primitive'
    
    % Theorem 8 - check that gs(h_m - 1) = gs(h_m-1)
    if gs(h_i(h_i_length) - 1 + 1) ~= gs(h_i(h_i_length-1) + 1)
        error(['Check failed for primitive sequence: ' ...
            'Require: gs(h_m - 1) = gs(h_m-1)']); 
    end
end



%% Use the terminal points to construct the production sequence.

% Note the first value in h_i is h_0, so its length is one more than the 
% length of the production history.
H = cell([1 (h_i_length-1)]);
for k = 1:(h_i_length-1)
    H{k} = S((h_i(k)+1):h_i(k+1));
end



%% Hence calculate the complexity.
if normalize
    % Normalized complexity
    C = length(H) / (n / log2(n));
else
    % Un-normalized complexity
    C = length(H);
end


%% Eigenfunction is returned.
% The (redundant) first value (gs(0) = 0) is removed first.
gs = gs(2:end);




