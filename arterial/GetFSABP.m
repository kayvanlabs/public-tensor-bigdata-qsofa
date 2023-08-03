function [Lmax, Lmin]=GetFSABP(data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               %get the location and value of data;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

% This function requires data to be a column vector
if not(iscolumn(data))
    data = transpose(data);
end

t = 0:length(data)-1; 

%logic vector for the local max value 
Lmax = diff(sign(diff(data)))== -2; 
% match the logic vector to the original vecor to have the same length 
Lmax = [false; Lmax; false];
%locations of the local max elements
Lmax = t (Lmax); 

%logic vector for the local min value 
Lmin = diff(sign(diff(data)))== 2; 
% match the logic vector to the original vecor to have the same length 
Lmin = [false; Lmin; false];
%locations of the local min elements
Lmin = t (Lmin); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Lmax = Lmax+1;
Lmin = Lmin+1;

end