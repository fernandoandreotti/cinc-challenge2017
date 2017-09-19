%BINARY_SEQ_TO_STRING String representation of a logical vector. 
%   This function takes a vector of logical values, and returns a string
%   representation of the vector.  e.g. [0 1 0 1 1] becomes '01011'.
%   
%   Usage: [s] = binary_seq_to_string(b)
%
%   INPUTS:
%   
%   b: 
%   A vector of logical values representing a binary sequence.
%   Numeric values will be converted to logical values depending on 
%   whether (0) or not (1) they are equal to 0.
%
%
%   OUTPUTS:
%
%   s:
%   A string representation of b.  The nth character in the string
%   corresponds with b(k).
%
%
%
%
%   Author: Quang Thai (qlthai@gmail.com)
%   Copyright (C) Quang Thai 2012
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

function [s] = binary_seq_to_string(b)


b = logical(b(:));
    

lookup_string = '01';

s = lookup_string(b + 1);
