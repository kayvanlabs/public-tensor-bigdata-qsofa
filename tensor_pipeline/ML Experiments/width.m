function W = width(X)
%WIDTH Number of columns in an array.
%   W = WIDTH(X) returns the number of columns in the array X.  WIDTH(X) is
%   equivalent to SIZE(X,2).
%
%   See also HEIGHT, SIZE, NUMEL.

%   Copyright 2020 The MathWorks, Inc.

W = size(X,2);
