function names = prepend_feature_names_with_signal_type(names, ...
                                                        signal_type, ...
                                                        winNum)
% DESCRIPTION: Takes each field of 'names'; loops through its contents
% (which are cell arrays of characters) and prepends the value of
% 'signal_type' to the char array in each cell.
%
% INPUTS
%   names           1x1 struct with several fields, each of which is a 
%                   type of feature that is being extracted
%      
%   signal_type     character array (i.e. 'ekg_i')
%   
%   winNum          integer-value > 0; represents which sub-window is being
%                   processed
%
% OUTPUTS
%   featureNames    1x1 struct; similar to the input but with each
%                   character array modified as indicated in the
%                   description
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: Sep 10, 2018
%%

fields = fieldnames(names);
n = length(fields);

for fieldIndex = 1:n
    namesInThisField = names.(fields{fieldIndex});
    names.(fields{fieldIndex}) = strcat(signal_type, '_subwin_', ...
                                        int2str(winNum), '_', ...
                                        namesInThisField);
end

end % eof