function samplingRate = get_sampling_rate(signalType)
% DESCRIPTION Returns the digital sampling rate (in Hertz) for input
% argument 'signalType'
%
% INPUTS 
%   signalType      character array (example: 'ekg_i')
%
% OUTPUTS
%   samplingRate    positive, integer-valued number (example: 240)
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: June 12, 2018
%%

switch(signalType)
    case {'ekg_i', 'ekg_ii', 'ekg_iii', 'ekg_Vi'}
        % EKG lines
        samplingRate = 240;

    case {'art', 'pap', 'cvp'}
        % Arterial Line; Pulmonary Artery Pressure; Central Venous Pressure
        samplingRate = 120;

    case {'resp', 'spo2', 'etco2'}
        % Respiratory; SpO2; EtCO2
        samplingRate = 60;

    otherwise
        samplingRate = 0;
end

end %eof