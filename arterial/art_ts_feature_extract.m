function [features,names] = art_ts_feature_extract(y,sigAttributes,...
                                                   epsilons,winNum)
% DESCRIPTION   Extracts features from taut string estimates of the
%               arterial (or an Spo2) signal.
%
% INPUTS
%   y                   vector: clean 1-D arterial or Spo2 signal
%      
%   signalAttributes    structure containing the following fields:
%                       'SignalType' & 'sampleRate'
%
%   epsilons            array of floats: the epsilons for Taut-String
% 
%   winNum              integer-value > 0; represents which sub-window is 
%                       being processed
% 
% OUTPUTS
%   features            structure containing Arterial or Spo2 features
%
%   names               structure containing Arterial or Spo2 feature names
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: Jan 19, 2019
%%
if iscolumn(y)
    % TautString function requires a row vector
    y = transpose(y);
end

sigType = (sigAttributes.signalType);
features = struct(sigType,[]);
names = struct(sigType,[]);

for i=1:length(epsilons)
    % Obtain Taut String Estimate of clean Arterial Waveform
    epsilon = epsilons(i);
    [yDenoised,~] = taut_string(y,epsilon);
    
    % Extract features from Taut String Estimate "yDenoised"
    [featuresWin,namesWin] = ...
                art_feature_extraction(yDenoised,sigAttributes,winNum);
    
    % Append the value of epsilon to the names for this window
    epsilonAsString = num2str(epsilon);
    namesWin.(sigType) = strcat(namesWin.(sigType),'_Epsilon_', ...
                                epsilonAsString);

    % Update the output with values obtained for this value of epsilon
    names.(sigType) = [names.(sigType); namesWin.(sigType)];
    features.(sigType)=[features.(sigType),featuresWin.(sigType)];
end

end % eof