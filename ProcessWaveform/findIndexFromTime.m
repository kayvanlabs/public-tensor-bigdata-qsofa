function foundIndices = findIndexFromTime(idNum, timeIn)
% Find an index in the signal based on datetime values
%
% Olivia Alge for BCIL, February 2020.
% Matlab 2019a, Windows 10
%
% DESCRIPTION
% Find an index in the signal based on the datetime values
%
% REQUIRES
% loadWaveformtimes.m
%
% INPUT
% idNum: numeric, patient ID number
% timeIn: datetime, time to find in the signal
% 
% OUTPUT
% foundIndices: struct with different indices for different signals
%
% EXAMPLE
% timeIn = datetime('20-Oct-2014 22:30:00', 'TimeZone', 'America/New_York')
% idNum = 400001015
%
% TODO: Add in other signals in addition to EKG

    waveformTimes = loadWaveformTimes();
    timesTable = waveformTimes(waveformTimes.Sepsis_ID == idNum, :);
    ecgFs = 240;
    foundIndices.EKG1 = findIndexEkg(timesTable, timeIn, ecgFs, 'EKG I');
    foundIndices.EKG2 = findIndexEkg(timesTable, timeIn, ecgFs, 'EKG II');
    foundIndices.EKG3 = findIndexEkg(timesTable, timeIn, ecgFs, 'EKG III');
    foundIndices.EKG4 = findIndexEkg(timesTable, timeIn, ecgFs, 'EKG IV');
end

function foundIndex = findIndexEkg(timesTable, timeToFind, fs, sigName)
% TODO: Handle if there are multiple wave ids
    timesSignal = timesTable(ismember(timesTable.WaveType, sigName), :);
    
    if isempty(timesSignal)
        foundIndex = nan;
        
    elseif size(timesSignal, 1) 
        ekgStart = timesSignal.StartTime;
        ekgEnd = timesSignal.EndTime;
        
        if (ekgStart > timeToFind) || (timeToFind > ekgEnd)
            foundIndex = nan;
            
        else
            timeDiff = seconds(timeToFind - ekgStart);
            foundIndex = timeDiff * fs;
            
        end
        
    else  %TODO: fill this -- multiple wave ids
        foundIndex = nan;
    end
end