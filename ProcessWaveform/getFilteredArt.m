function tableOut = getFilteredArt(tableIn)
% Filter available Arterial Line signals within loaded table
%
% Olivia Alge for BCIL, April 2022.
% Matlab 2020b, Windows 10
%
% DESCRIPTION
% Filters and scales all Art Line signals and returns them to output
%
% INPUT
% tableIn: table containing Art signals, of format 
%          nRows x (SepsisID, Label, ABP)
% 
% OUTPUT
% tableOut: tableIn, but with Signals processed
    
    % Initialize tableOut
    nSignals = size(tableIn, 1);
    tableOut = tableIn;
    artCol = contains(tableIn.Properties.VariableNames, 'ABP');
    tableOut.Properties.VariableNames{artCol} = 'Filtered_Art';

    for i = 1:nSignals   
        iArt = cell2mat(tableIn{i, 'ABP'});
        iFiltered = performFiltering(iArt);
        tableOut{i, 'Filtered_Art'} = {iFiltered};
    end
end

function filteredOut = performFiltering(signalIn)
%% Modified from Larry Hernandez's DOD/matlab/arterial/ code
    fsArt = 120;  % Sampling rate of Art Line
    orderBP = 3;
    fLow = 0.75;  % 4 Hz is upper bound for typical heart rates
    fHigh = 30;
    
    wn = [fLow, fHigh] * 2 / fsArt; % cutoff based on sampling Rate
    [a, b] = butter(orderBP, wn, 'bandpass');
    
    filteredOut = filtfilt(a, b, signalIn);
end