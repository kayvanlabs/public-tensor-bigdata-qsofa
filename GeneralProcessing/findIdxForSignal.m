function idx = findIdxForSignal(waveformTimes, signalCol, signalName)
% DESCRIPTION
% Generate row indices from waveformTimes for specific signal type
%
% INPUT
% waveformTimes: table of waveform times
% signalCol: char, column of waveform times containing signal names
% signalName: char, entry of waveformTimes.(signalCol) to select for
%
% OUTPUT
% idx: logical, column of indices, 1 is match for signalName
    idx = ismember(waveformTimes.(signalCol), signalName);
end