function boolValue = is_constant(x)
% DESCRIPTION: checks if an array is constant (ie, all values are the same)
%
% INPUT
%     x            array of numbers
% OUTPUT
%     boolValue    true or false
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: April 16, 2018
%% 

if all(x == x(1))
    boolValue = true;
else
    boolValue = false;
end

end % eof