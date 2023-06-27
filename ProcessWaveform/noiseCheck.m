function output = noiseCheck(configFile, signalsInfo)
% DESCRIPTION
%   Check noise level of available ECG
%
% REQUIRES
%   Winston's noise detection code
%
% INPUT
%   configFile: struct that contains file paths
%   signalsInfo: table with SepsisID, start/end times of signals,
%                difference in time between waveform times duration and
%                actual duration (AbsVal_TimeStampDur_minus_Duration)
%
% OUTPUT
%   output: table with ID column SepsisID that gives information on
%           usable signal data 
%
% Matlab 2020b, Windows 10
% Olivia Pifer Alge
% November 2021
    output = [];
    addpath('noiseDetectionECG')
    diffCol = 'AbsVal_TimeStampDur_minus_Duration';
    percent_not_noisy = zeros(size(output, 1), 1);
    % Don't bother checking samples with discrepancies greater than an hour
    rowsToRemove = signalsInfo.(diffCol) > hours(1);
    signalsInfo = signalsInfo(~rowsToRemove, :);
    
    for i = 1:size(signalsInfo, 1)
        iId = signalsInfo{i, 'Sepsis_ID'};
        iWaveId = signalsInfo{i, 'WaveID'};
        sigName = signalsInfo{i, 'WaveType'};
        fs = 240;  % sampling rate
        iFileName = append(num2str(iId), '_', ...
                           signalsInfo{i, 'Sepsis_EncID'}, '_', ...
                           sigName, '_', ...
                           iWaveId);
        iFilePath = fullfile(configFile.extracted, ...
                             append(iFileName, '.csv'));
        
        try 
            if ~contains(sigName, 'EKG')
                error('must be EKG')
            end
            iFullSignal = readCsvWithScan(char(iFilePath));
            iSignal = iFullSignal; %iFullSignal(round(iStartIdx):round(iEndIdx));

            ecg = preprocess_ecg(iSignal,fs,'BP',1); % remove baseline wander and smooth signal
            win_length = fs*10;                  % divide ecg into windows of 10 second length

        % get noise annotations, R peak indices, and other data
            [noisy,~,~,~,~,~] = new_noise_detect_WZ_shared(ecg, fs, win_length);
            percent_not_noisy(i) = (length(noisy) - sum(noisy)) / length(noisy);
        catch ME
            warning(['something went wrong at i = ', num2str(i)])
            disp(ME.message);
            percent_not_noisy(i) = -1;
            noisy = -1;
        end
        disp(['Iteration ', num2str(i)]);
        save('percent_not_noisy.mat', 'percent_not_noisy');
        save(['noisy_nonspecific/noisy_', num2str(i), '.mat'], 'noisy', '-v7.3')
    end
    output.percent_not_noisy = percent_not_noisy;
end