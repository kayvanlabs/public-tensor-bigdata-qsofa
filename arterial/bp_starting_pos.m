function [footIndex,idxS,idxD] = bp_starting_pos(footIndex,idxS,idxD)
% DESCRIPTION   Determine the starting positions of each of the three 
%               arrays of indices, particularly when they are of different
%               length
% 
% INPUTS
%   footIndex   vector: indices of the foot
%   idxS        vector: indices of systolic peaks
%   idxD        vector: indices of dicrotic peaks
% 
% OUTPUTS
%   footIndex   vector: indices of the foot
%   idxS        vector: indices of systolic peaks
%   idxD        vector: indices of dicrotic peaks
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: Dec 20, 2018
%%

nf = length(footIndex);
ns = length(idxS);
nd = length(idxD);

% Determine the common length of the 3 arrays of indices
if (nf == ns && ns == nd)
    n = nf;
else
    n = min([nf,ns,nd]);
end

% Determine the first "sensible" starting array value
start = first_prop_ordered_foot_sys_dicr(footIndex,idxS,idxD);

% Subset the arrays
footIndex = footIndex(start:n);
idxS = idxS(start:n);
idxD = idxD(start:n);
end % eof