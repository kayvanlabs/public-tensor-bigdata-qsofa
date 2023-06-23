function rowToAdd = createRandomStart(earliestStart, latestStart, signalDuration, thisEvent, wavTab, gapDuration)
% DESCRIPTION
% Create a random event time for negative cases
%
% REQUIRES
% convertTime()
%
% INPUT
%   earliestStart: datetime, earliest possible start of EKG signal for event
%   latestStart: datetime, latest possible start of EKG signal for event
%   signalDuration: duration, desired length of precdiction signal
%   thisEvent: table, event information from find<event>Occurrences.m
%   wavTab: table, waveform times
%   gapDuration: duration, time between end of prediction signal and event
%
% OUTPUT
%   rowToAdd: table built from thisEvent and wavTab with added columns:
%       randomEventTime
%       predictionSignalStart
%       predictionSignalEng
    
    % Generate a random signal start time
    tempRand = randi([uint64(convertTime(earliestStart)), ...
                      uint64(convertTime(latestStart))], 1, 1);
    randomStart = convertTime(tempRand);
    predictionSignalStart = randomStart;
    
    % Calculate end of signal
    predictionSignalEnd = predictionSignalStart + signalDuration;
    rowToAdd = innerjoin(thisEvent, wavTab);
    nRows = size(rowToAdd, 1);
    
    % Calculate event time
    randomEtime = randomStart + gapDuration + signalDuration;
    
    % Store times to output
    rowToAdd.RandomEventTime = repelem(randomEtime, nRows)';
    rowToAdd.predictionSignalStart = repelem(predictionSignalStart, nRows)';
    rowToAdd.predictionSignalEnd = repelem(predictionSignalEnd, nRows)';
end