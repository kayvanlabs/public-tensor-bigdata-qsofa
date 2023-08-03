function foundIndices = find_signal_index_from_time(waveformTimes, idNum, encId, timeIn, sigName, waveId)
% DESCRIPTION
% Find an index in the signal based on the datetime values
%
% INPUT
% waveformTimes: table of waveform times
% idNum: numeric, patient ID number
% encId: char vector, encounter ID
% timeIn: datetime, time to find in the signal
% sigName: char vector, name of signal to select
% waveId: char vector, waveID associated with sigal
% 
% OUTPUT
% foundIndices: struct with different indices for different signals
%
% EXAMPLE
% timeIn = datetime('20-Oct-2014 22:30:00', 'TimeZone', 'America/New_York')
% idNum = 400001015
%
% Olivia Alge for BCIL, November 2020.
% Matlab 2019a, Windows 10
% TODO: Add in other signals in addition to EKG
    waveformTimes.Properties.VariableNames{1} = 'SepsisID';
    idCondition = waveformTimes.SepsisID == idNum;
    encCondition = strcmp(waveformTimes.Sepsis_EncID, encId);
    waveCondition = strcmp(waveformTimes.WaveType, sigName);
    waveIdCondition = strcmp(waveformTimes.WaveID, waveId);
    matchedCondition = idCondition & encCondition & waveCondition & waveIdCondition;
    timesTable = waveformTimes(matchedCondition, :);
    foundIndices = [];
    
    if contains(sigName, 'EKG')
        fs = 240;
    elseif contains(sigName, 'Art')
        fs = 120;
    else
        return        
    end
    foundIndices = findIndexEkg(timesTable, timeIn, fs, sigName);
end

function foundIndex = findIndexEkg(timesTable, timeToFind, fs, sigName)
% TODO: Handle if there are multiple wave ids
    timesSignal = timesTable(ismember(timesTable.WaveType, sigName), :);
    
    if isempty(timesSignal)
        foundIndex = nan;
        return

    % Get start and end of signal
    elseif size(timesSignal, 1) == 1
        ekgStart = timesSignal.StartTime;
        ekgEnd = timesSignal.EndTime;
    else  
        endAllSame = all(timesSignal.EndTime == timesSignal.EndTime(1));
        startAllSame = all(timesSignal.StartTime == timesSignal.StartTime(1));
        if endAllSame && startAllSame
            ekgStart = timesSignal.StartTime(1);
            ekgEnd = timesSignal.EndTime(1);
        else
            foundIndex = nan;
            return
        end
    end
    
    % Get index
    if (ekgStart > timeToFind) || (timeToFind > ekgEnd)
        foundIndex = nan;

    else
        timeDiff = seconds(timeToFind - ekgStart);
        foundIndex = max(timeDiff * fs, 1);
    end
end