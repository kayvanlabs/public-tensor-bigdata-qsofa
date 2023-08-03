function idx = first_prop_ordered_foot_sys_dicr(footIndex,idxS,idxD)
% DESCRIPTION   Determine the value of the index when the foot, systole,
%               and dicrotic peaks occur in a seemingly correct order (i.e.
%               foot(index) < idxS(index) < idxD(index)
% 
% INPUTS
%   footIndex   vector: indices of the foot
%   idxS        vector: indices of systolic peaks
%   idxD        vector: indices of dicrotic peaks
% 
% OUTPUTS
%   idx         integer valued number (and index)
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: Dec 23, 2018
%%

for jj=1:length(footIndex)
   if (footIndex(jj) < idxS(jj)) && (idxS(jj) < idxD(jj))
        idx = jj;
        return;
   end
end

idx = [];

end % eof