function [allSignalsInfo, uniqueIDs] = generateSignalsInfoForEvent(signalsInfo, configFile, gapDuration, signalDuration, eventName)
% DESCRIPTION
% Prepare Raw ECG/Art Line data to be processed by load_nonspecific_raw.mat
%
% REQUIRES
% find_signal_index_from_time(), enforce_1_by_N(), findOutcomesForQSOFA(),
% findOutcomesForSOFA()
%
% INPUT
% configFile: struct of directories
% gapDuration: duration, length of prediction gap in minutes
% signalDuration: duration, length of signal to store in minutes
% eventName: char, 'qSOFA' or 'SOFA'
	%% Load the data
    disp('Loading Data');

    % fn = load(configFile.nonspecific.dataDir);
    % signalsInfo = fn.signalsInfo;
    thisConfig = configFile.nonspecific;

    %% Labels
    idEncCols = {'SepsisID', 'Sepsis_ID', 'Sepsis_EncID', 'SepsisEncID'};
    [eventPos, eventNeg, outDir, findOutcomeFunc] = assignValsForEvent(eventName, thisConfig);
    
    %% Extract the unique IDs for these patients
    idColIdx = ismember(signalsInfo.Properties.VariableNames, idEncCols);
    [uniqueIDs, uniqueIDsIdx] = unique(signalsInfo(:, idColIdx));
    
    %% Get signalsInfo for positive and negative outcomes
    [signalsInfoPositives, ...
     signalsInfoNegatives] = findOutcomeFunc(thisConfig.(lower(eventName)), ...
                                             thisConfig.noise, ...
                                             signalsInfo, ...
                                             gapDuration, ...
                                             signalDuration);

    signalsInfoPositives.Properties.VariableNames{1} = 'Sepsis_ID';
    signalsInfoNegatives.Properties.VariableNames{1} = 'Sepsis_ID';
    
    % Get Unique IDs for positive and negative
    idColIdx = ismember(signalsInfoPositives.Properties.VariableNames, idEncCols);
    uniqueIDsPos = unique(signalsInfoPositives(:, idColIdx));
    uniqueIDsNeg = unique(signalsInfoNegatives(:, idColIdx));
    
    % Assign outcomes
    outcomesPos = repelem(1, size(signalsInfoPositives, 1))';
    outcomesNeg = repelem(0, size(signalsInfoNegatives, 1))';
    
    %% Extract the signal for each of these outcomes
    
    % Load event times
    signalsInfoPositives.EventTime = signalsInfoPositives.(eventPos);
    signalsInfoNegatives.EventTime = signalsInfoNegatives.(eventNeg);
    signalsInfoPositives.EncodedOutcome = strrep(string(num2str(signalsInfoPositives.qSofaEncoding)), ' ', '');
    signalsInfoNegatives.EncodedOutcome = strrep(string(num2str(signalsInfoNegatives.qSofaEncoding)), ' ', '');
    
    % TODO: Don't hardcode these
    columnOrder = [{'Sepsis_ID'}, {'Sepsis_EncID'}, {'WaveType'}, ...
                   {'WaveID'}, {'StartTime'}, {'EndTime'}, ...
                   {'predictionSignalStart'}, {'predictionSignalEnd'}, ...
                   {'ObservationDate'}, {'EventTime'}, {'EncodedOutcome'}, ...
                   {'qSofaTotal'}, {'BPSysNonInvasive'}, {'BPSysInvasive'}, ...
                   {'RespiratoryRate'}, {'GCS'}, {'yearFile'}];
    allSignalsInfo = [signalsInfoPositives(:, columnOrder); ...
                      signalsInfoNegatives(:, columnOrder)];
    
    %% Save to file
    specsName = generateSpecsName(gapDuration, signalDuration); 
    saveName = fullfile(outDir, specsName);
    save(saveName, 'allSignalsInfo', '-v7.3');
end

function [eventPos, eventNeg, outDir, findOutcomeFn] = assignValsForEvent(eName, configFile)
% Assign column and function names based on event name    
    if strcmpi(eName, 'qSOFA')
        eventPos = 'ObservationDate';
        eventNeg = 'RandomEventTime';
        outDir = configFile.qsofa;
        findOutcomeFn = @findOutcomesForQSOFA;
    elseif strcmpi(eName, 'SOFA')
        eventPos = 'eventTime';
        eventNeg = 'RandomEventTime';
        outDir = configFile.sofa;
        findOutcomeFn = @findOutcomesForSOFA;
    end
end

function specsName = generateSpecsName(gapDur, sigDur)
    gapStr = "gap_" + strrep(string(gapDur), ' ', '_') + "_";
    sigStr = "signal_" + strrep(string(sigDur), ' ', '_');
    specsName = "signalsInfo_" + gapStr + sigStr + ".mat";
end