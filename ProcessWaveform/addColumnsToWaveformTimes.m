function signalsInfo = addColumnsToWaveformTimes(configFile, waveformTimes, groupChar)
% DESCRIPTION Create table of information for signal name and duration
%
% INPUTS
%   waveformTimes  MATLAB table containing metadata about the signals 
%   groupChar      character vector
% 
% OUTPUTS
%   tableOfRecords  MATLAB table: a sorted version of the input argument
% 
% REQUIRES        
%   waveformTimes has these 4 columns:
%       {'Sepsis_ID', 'Sepsis_EncID', 'WaveType', 'WaveID'}
%   signal_type_abbreviation(), get_sampling_rate(), readCsvWithScan()
% 
% Language: MATLAB R2019a
% OS: Windows 10
% Author: Olivia Alge
% Date: April 2020

    extractedDir = configFile.extracted;
    durationFile = 'nonspecificWaveformDurations.mat';
    
    % Initialize output
    Duration = zeros(size(waveformTimes, 1), 1);
    sigNames = cell(1, size(waveformTimes, 1));

    % Calculate duration information for each signal
    for i = 1:size(waveformTimes, 1)
        iObj = waveformTimes(i, :);
        iSigType = signal_type_abbreviation(char(iObj.WaveType));
        iSamplingRate = get_sampling_rate(iSigType);
        iDirName = strjoin({num2str(iObj.Sepsis_ID), ...
                            char(iObj.Sepsis_EncID), ...
                            char(iObj.WaveType), ...
                            char(iObj.WaveID)}, ...
                            '_');
        sigNames{i} = iDirName;
        
        fileToRead = fullfile(extractedDir, [iDirName, '.csv']);
        
        % Read file and get duration
        iDuration = computeSignalDuration(fileToRead, iSamplingRate);
        Duration(i) = iDuration;
        
        save(durationFile, 'sigNames', 'Duration');
        
        % Display loop iteration
        disp(['Iteration ', num2str(i), ' out of ', ...
               num2str(size(waveformTimes, 1)) '...']);
    end
    
    % Save output to file
    save(durationFile, 'sigNames', 'Duration');
    
    % Add additional columns
    signalsInfo = addTheColumns(waveformTimes, Duration, sigNames);
end

function signalDuration = computeSignalDuration(signalFile, samplingRate)
% DESCRIPTION
% Open signalFile by loading it in in chunks and return the length of the
% signal
%
% INPUT
% signalFile: char, location of signal file
%
% OUTPUT
% signalLength: numeric, length of signal in seconds

    if isfile(signalFile)
        signalLength = length(readCsvWithScan(signalFile));
        signalDuration = signalLength / samplingRate;
    else  % if file does not exist
        signalDuration = nan;
    end
end

function waveformTimesOut = addTheColumns(waveformTimesIn, Duration, sigNames)
% DESCRIPTION
% Add columns to waveformTimes
%
% INPUT
% waveformTimesIn: table, waveformTimes
% Duration: actual duration of signal
% sigNames: names of signals (ekg ii and art)
%
% OUTPUT
% waveformTimesOut: waveformTimesIn with additional columns
    nSignals = length(sigNames);
    
    nanVec = nan(nSignals, 1);
    TimeStampDuration_minus_Duration = duration(0, 0, nanVec);
    
    Duration = duration(0, 0, Duration);
    
    for i = 1:nSignals
        iSigName = sigNames{i};
        if isequal(str2double(iSigName(1:9)), waveformTimesIn.Sepsis_ID(i))
            dDiff = waveformTimesIn.DurationStartMinusEnd(i) - Duration(i);
            TimeStampDuration_minus_Duration(i) = dDiff;
        end
    end
    AbsVal_TimeStampDur_minus_Duration = abs(TimeStampDuration_minus_Duration);

    waveformTimesOut = [waveformTimesIn, table(Duration), ...
                        table(TimeStampDuration_minus_Duration), ...
                        table(AbsVal_TimeStampDur_minus_Duration)];
end