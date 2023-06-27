function shortText = signal_type_abbreviation(longText)
% DESCRIPTION Given a filename, determine the type of waveform that is
% described by the data
%
% INPUTS
%   longText          string describing type of waveform (ie, 'Art Line')
%
% OUTPUTS
%   shortText         abbreviated description for type of waveform
% 
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: January 27, 2019
%%

% Abbreviate the description
switch(longText)
    
    case 'Art Line'
        shortText = 'art';
    
    case 'CVP - Central Venous Pressure'
        shortText = 'cvp';
    
    case 'EKG I'
        shortText = 'ekg_i';
        
    case 'EKG II'
        shortText = 'ekg_ii'; 

    case 'EKG III'
        shortText = 'ekg_iii';

    case 'EKG IV'  % 'EKG IV' is actually the V_I lead
        shortText = 'ekg_Vi';

    case 'PA - Pulmonary Artery Pressure'
        shortText = 'pap';
        
    case 'Respiratory'
        shortText = 'resp';

    case 'SpO2'
        shortText = 'spo2';

    case 'EtCO2'
        shortText = 'etco2';
        
    otherwise
        error('Signal type not known. Check the filenames');
end

end % eof