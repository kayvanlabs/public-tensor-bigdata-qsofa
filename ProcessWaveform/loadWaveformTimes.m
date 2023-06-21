function waveformTimes = loadWaveformTimes(timesFileLocation)
% Load the waveform times table
%
% DESCRIPTION
% Loads the excel table that lists sepsis ID, signal type, and start and
% end times of signal
%
% REQUIRES
% Existence of waveform times .xlsx file
% Excel file has six columns, with the following six variables (in order):
%  [ Sepsis_ID, Sepsis_EncID, WaveType, WaveID, StartTime, EndTime ]
%
% INPUT
% timesFileLocation: char vector, gives the location of the .xlsx file that 
%                    provides waveform times
% groupChar: char vector, describes group, can be one of the following:
%            'pediatric': for pediatric data
%            'troponin': For troponin data
%
% OUTPUT
% wavformTimes: table, contains start/end times of different signals
%
% Olivia Pifer Alge for BCIL, October 2021
% Matlab 2020b, Windows 10

    % Set options
    opts = setOpts();

    % Import the data
    waveformTimes = setTimeZone(readtable(timesFileLocation, opts, ...
                                "UseExcel", false));

    % Add duration column
    DurationStartMinusEnd = waveformTimes.EndTime - waveformTimes.StartTime;
    waveformTimes(:, 'DurationStartMinusEnd') = table(DurationStartMinusEnd);
end

function optStruct = setOpts()
% Sets up structure 'optStruct' of options for reading in the excel file
% REQUIRES
% assignDataRange()
    nVariables = 6;
    optStruct = spreadsheetImportOptions("NumVariables", nVariables);
    optStruct.DataRange = "A2:F5550";  % columns of spreadsheet
    
    optStruct.VariableTypes = ["double", "char", "char", ...
                               "char", "string", "string"];
    optStruct.VariableNames = ["Sepsis_ID", "Sepsis_EncID", "WaveType", ...
                               "WaveID", "StartTime", "EndTime"];
    
    % Handle issues with whitespace
    optStruct = setvaropts(optStruct, [3, 5, 6], "WhitespaceRule", "preserve");
    optStruct = setvaropts(optStruct, [3, 5, 6], "EmptyFieldRule", "auto");
end

function waveformTimesOut = setTimeZone(waveformTimesIn)
% Set time zone of waveform times to America/New York
% Have to read dates in as string then convert to datetime because
% Matlab has issues with excel's time zone (e.g. 15:00 in the excel 
% file yields 00:00 EST, when it should be 15:00 EST)
    zoneStr = 'America/New_York';
    waveformTimesOut = waveformTimesIn;
    
    startTime = datetime(waveformTimesIn.StartTime, 'TimeZone', zoneStr);
    endTime = datetime(waveformTimesIn.EndTime, 'TimeZone', zoneStr);
    
    waveformTimesOut.StartTime = startTime;
    waveformTimesOut.EndTime = endTime;
end