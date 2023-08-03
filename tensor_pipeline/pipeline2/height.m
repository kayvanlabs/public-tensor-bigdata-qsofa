function H = height(X)
%HEIGHT Number of rows in an array.
%   H = HEIGHT(X) returns the number of rows in the array X.  HEIGHT(X) is
%   equivalent to SIZE(X,1).
%
%   See also WIDTH, SIZE, NUMEL.

%   Copyright 2020 The MathWorks, Inc.

H = size(X,1);
