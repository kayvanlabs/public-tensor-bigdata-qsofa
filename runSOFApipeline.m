function runSOFApipeline(gapDuration, signalDuration, nWindows, discrepDuration)
% DESCRIPTION
% A pipeline to identify instances of qSOFA, extract signals from ECG
% and Art Line related to these instances, compute features from these
% signals, and create & decompose tensors of these features.
%
% INPUT
%   gapDuration: duration, gap between end of signal and start of event
%       i.e. gapDuration = hours(6) or hours(12)
%   signalDuration: duration, length of ECG/Art Line signals
%       i.e. signalDuratio = minutes(10)
%   nWindows: numeric, number of windows to divide signalDuration into
%       i.e. nWindows = 2
%   discrepDuration: duration, tolerance for difference between recorded
%                    signal length and actual signal length
%       i.e. discrepDuration = hours(1);

    outcomeName = 'qSOFA';
    signalsUsing = 'ECG_Art';
    
    % ECG Sampling rate is 240 Hz, Art Line is 120 Hz
    
    %% Load in paths
    addpath('GeneralProcessing/');
    addpath(genpath('ProcessWaveform/'));
    addpath('qsofaScore');
    configFile = jsondecode(fileread('config.json'));  % paths for data
    
    %% First, if needed, generate outcomes
    runFindQsofaScript(configFile);
    
    %% If needed, process EHR
    addpath('ehr')
    processEhr(configFile.ehr);
    
    %% Generate Signals Information
    waveformTimes = loadWaveformTimes(configFile.waveformTimes);
    waveformTimes = waveformTimes(selectDesiredSignals(waveformTimes), :);
    
    % Select signals at or below discrepancy threshold
    signalsInfo = addColumnsToWaveformTimes(configFile, waveformTimes);
    colName = 'AbsVal_TimeStampDur_minus_Duration';
    signalsInfo = selectSigsBelowThresh(signalsInfo, colName, discrepDuration);
    
    % If needed, check noise level of signals
    noiseCheck(configFile, signalsInfo);
       
    %% Create the status variable
    allSignalsInfo = findOutcomesForQSOFA(configFile.qsofa, configFile.noise, ...
                                          signalsInfo, hours(0), signalDuration);
    a = [];
    b = [];
    c = [];
    for i = 1:size(allSignalsInfo)
        [enc, stat] = getEncAndStat(allSignalsInfo{i, 'Sepsis_EncID'});
        a = [a; enc];
        b = [b; stat];
        c = [c; string(strrep(num2str(signalsInfo{1, 'qSofaEncoding'}), ' ', ''))];
    end
    allSignalsInfo.Sepsis_EncID = a;
    allSignalsInfo.Status = b;
    allSignalsInfo.EncodedOutcome = c;
    signalsInfo = allSignalsInfo;
    signalsInfo.Properties.VariableNames{1} = 'Sepsis_ID';
    signalsInfo.Properties.VariableNames{2} = 'EventTime';
    
    %% Generate positive and negative outcomes
    [posCondition, negCondition] = createQsofaCriteria1to2(signalsInfo, gapDuration, signalDuration);
    signalsInfo = [posCondition; negCondition];
    
    %% Integrate EHR data
    gapStr = strcat('signalsInfo_gap_', num2str(hours(gapDuration)), '_hr_');
    sigStr = strcat('signal_', num2str(minutes(signalDuration)), '_min');
    fFile = fullfile(configFile.(lower(outcomeName)), ...
                     strcat(gapStr, sigStr, '.mat'));
    tempEhrFile = fullfile(configFile.ehr, 'temporalEHR.mat');
    save(fFile, 'signalsInfo')
    integrateTemporalEhrFeatures(fFile,tempEhrFile, gapDuration, signalDuration, nWindows);
    [rawEcgTable, rawAbpTable] = prepareRawSignals(configFile, signalsInfo, signalDuration);
    
    %% Get filtered Signals
    addpath('QRS_detection\')
    [~, filteredEcgTable, ~] = getQrsAndFilteredEcg(rawEcgTable);
    filteredAbpTable = getFilteredArt(rawAbpTable);
    eFile = fullfile(configFile.(lower(outcomeName)), ...
                     strcat(gapStr, sigStr, '_temporalEHR.mat'));
    tempEhr = load(eFile);
    filteredAbpWithEhr = appendEhrData(filteredAbpTable, tempEhr.features);
    [filteredEcgWithEhr, ehrNames] = appendEhrData(filteredEcgTable, tempEhr.features);
    
    save('filteredEcgWithEhr.mat', 'filteredEcgWithEhr')
    save('filteredAbpWithEhr.mat', 'filteredAbpWithEhr')
    
    %% Run pipeline2
    % Get tensors for ECG and Art Line
    addpath(genpath('tensor_pipeline/'));
    addpath(genpath('tensor_toolbox-master/'))  % From Sandia lab
    expName = generateDataAndExperimentName(signalsUsing, gapDuration, signalDuration);
    driver_tensorize(outcomeName + "ECG", "ECG_" + expName + "_TS", "TS", nWindows);
    driver_tensorize(outcomeName + "Art", "Art_" + expName + "_ABP", "ABP", nWindows);

    % Compile tensors
    compile_tensors(outcomeName + "ECG", "ECG_" + expName + "_TS");
    compile_tensors(outcomeName + "Art", "Art_" + expName + "_ABP");
    
    % Reduce tensors
    for seed = 0:99
        driver_decomp(outcomeName + "ECG", "ECG_" + expName + "_TS", nWindows, false, seed);
        driver_decomp(outcomeName + "Art", "Art_" + expName + "_ABP", nWindows, false, seed);
    end 
    
    disp('Data generated, ready to train models');
end

function idx = selectDesiredSignals(waveformTimes)
    % Only use ECG and Art Line
    eIdx = findIdxForSignal(waveformTimes, 'WaveType', 'EKG II');
    aIdx = findIdxForSignal(waveformTimes, 'WaveType', 'Art Line');
    idx = eIdx | aIdx;
end

function sigInfo = selectSigsBelowThresh(sigInfo, discrepCol, discrepTime)
% DESCRIPTION
% Find signals that have a discrepancy less than or equal to the threshold
%
% INPUT
% sigInfo: table of signalsInfo
% discrepCol: char, Column of signInfo that has absolute value of
%             difference between logged duration of signal and actual duration
%             of signal based on sampling rate
%
% OUTPUT
% idx: logical column vector, 1 is that the discrepancy is less than or
%      equal to discrepTime
    idx = sigInfo.(discrepCol) <= discrepTime;
    sigInfo = sigInfo(idx, :);
end

function [experimentName] = generateDataAndExperimentName(signalsUsing, gapDur, signalDur)
    pName = "prediction_" + num2str(minutes(gapDur)) + "_minutes_";
    sName = "signal_" + num2str(minutes(signalDur)) + "_minutes_";
    experimentName = pName + sName + string(signalsUsing);
end

function runFindQsofaScript(configFile)
    baseLocation = configFile.ehr;
    saveLocation = configFile.qsofa;
    for i = 14:18  % year files 14-18
        % Load EHR and Flowsheet data
        iEhrFile = strcat('ehrStruct_20', num2str(i), '.mat');
        iEhr = load(fullfile(baseLocation, iEhrFile));
        
        iFlowFile = strcat('flowsheet_20', num2str(i), '.mat');
        iFlowsheet = load(fullfile(baseLocation, iFlowFile));
        iFlowFields = fieldnames(iFlowsheet);
        
        % Call the qSOFA script
        qsofa = findqSofaOccurrences(iEhr.ehrStruct.vitalsStandard, ...
                                     iFlowsheet.(iFlowFields{1}));
        save(fullfile(saveLocation, strcat('qsofa', num2str(i))), 'qsofa');
    end
end
