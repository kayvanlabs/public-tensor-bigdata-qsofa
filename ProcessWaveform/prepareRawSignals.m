function [rawEcgTable, rawAbpTable] = prepareRawSignals(configFile, allSignalsInfo, signalDuration)
% REQUIRES
% find_signal_index_from_time()
    %% Create empty tables
    nRows = size(allSignalsInfo, 1);
    colNamesEcg = ["SepsisID", "Sepsis_EncID", "Label", "ECG"];
    colNamesAbp = ["SepsisID", "Sepsis_EncID", "Label", "ABP"];
    dirExtracted = configFile.nonspecific.extracted;
    rawEcgStruct = initializeRawStruct(nRows / 2, colNamesEcg);
    rawAbpStruct = initializeRawStruct(nRows / 2, colNamesAbp);
    
    %% Fill tables
    % Iterate on twos because the table alternates ECG-ABP
    iterCount = 1;
    for i = 1:2:nRows-1
        try
            % Get ECG signal
            [iEcg, ...
             iEcgRow] = createPredictionSignal(allSignalsInfo(i, :), ...
                                               dirExtracted, signalDuration);
            rawEcgStruct = updateRawStruct(rawEcgStruct, iterCount, ...
                                           colNamesEcg, iEcgRow, iEcg);
            
            % Get Arterial Line
            [iAbp, ...
             iAbpRow] = createPredictionSignal(allSignalsInfo(i + 1, :), ...
                                               dirExtracted, signalDuration);
            rawAbpStruct = updateRawStruct(rawAbpStruct, iterCount, ...
                                           colNamesAbp, iAbpRow, iAbp);
        catch ME
            disp(ME.identifier);
            continue
        end
        disp("Iteration " + num2str(i) + " of " + num2str(nRows))
        iterCount = iterCount + 1;
    end
    rawEcgTable = struct2table(rawEcgStruct);
    rawAbpTable = struct2table(rawAbpStruct);
end

function rawStruct = initializeRawStruct(nRows, colNames)
% Initialize structure for output. I would prefer to use a table rather
% than cast a struct to a table, but Matlab doesn't allow initializing a
% table with a double array; it does allow initializing a struct with a
% double array.
    rawStruct.(colNames(1)) = 0;
    rawStruct.(colNames(2)) = 0;
    rawStruct(nRows).(colNames(3)) = [0,0];
end

function [predictionSignal, sigRow] = createPredictionSignal(sigRow, dirExtracted, signalDuration)
% Subset the full signal to only select the desired time 
% REQUIRES
% getStartAndEndIndices
    aMinute = 60;
    if contains(sigRow.WaveType, 'EKG')
        fs = 240;
    elseif contains(sigRow.WaveType, 'Art')
        fs = 120;
    else
       error('Unknown signal type')    
    end
    
    expectedSignalLength = seconds(signalDuration) * fs;
    sigFile = fullfile(dirExtracted, makeSigName(sigRow));
    sigStart = getStartAndEndIndices(sigRow);
    sigEnd = (sigStart + expectedSignalLength) - 1;
    fullSignal = csvread(sigFile);
    
    % Check if full length doesn't extend past available signal
    if sigEnd > length(fullSignal)
        amountMissing = length(fullSignal) - sigEnd;
        % If only a small amount missing, just shift window over slightly
        if amountMissing <= (fs * aMinute)
            sigStart = sigStart - amountMissing;
            sigEnd = sigEnd - amountMissing;
        end
    end
    
    predictionSignal = fullSignal(sigStart:sigEnd);
end

function [startIdx, endIdx] = getStartAndEndIndices(rowIn)
% Get the start and end indices for the prediction signal
% REQUIRES
% find_signal_index_from_time()
    startIdx = find_signal_index_from_time(rowIn, ...
                                           rowIn.Sepsis_ID,...
                                           rowIn.Sepsis_EncID, ...
                                           rowIn.predictionSignalStart, ...
                                           rowIn.WaveType, ...
                                           rowIn.WaveID);
    endIdx = find_signal_index_from_time(rowIn, ...
                                         rowIn.Sepsis_ID,...
                                         rowIn.Sepsis_EncID, ...
                                         rowIn.predictionSignalEnd, ...
                                         rowIn.WaveType, ...
                                         rowIn.WaveID);
end

function sigName = makeSigName(allSignalsRow)
% Create a file name given information from the signal in allSignalsRow
    sigName = num2str(allSignalsRow.Sepsis_ID) + "_" + ...
              string(allSignalsRow.Sepsis_EncID) + "_" + ...
              string(allSignalsRow.WaveType) + "_" + ...
              string(allSignalsRow.WaveID) + ".csv";
end

function rawStruct = updateRawStruct(rawStruct, idx, colNames, thisRow, thisSignal)
% Update the struct with the newly subset signals
    idIdx = 1;
    encIdx = 2;
    outcomeIdx = 3;
    sigIdx = 4;

    % ID
    rawStruct(idx).(colNames(idIdx)) = thisRow.Sepsis_ID;
    % EncID
    rawStruct(idx).(colNames(encIdx)) = thisRow.Sepsis_EncID;
    % Label
    rawStruct(idx).(colNames(outcomeIdx)) = thisRow.Label;
    % Signal
    if size(thisSignal, 1) == 1
        thisSignal = thisSignal';
    end
    rawStruct(idx).(colNames(sigIdx)) = thisSignal;
end