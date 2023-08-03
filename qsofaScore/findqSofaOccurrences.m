function qSofaTimes = findqSofaOccurrences(vitals, flowsheet)
% Create table with datetimes where 2/3 qSOFA conditions 
% (Respiratory rate >= 22/min, systolic blood pressure <= 100 mmHg, GCS < 15)
% are met
%
% INPUT
% vitals: table from ehr data vitals, has RR and systolic BP
% flowsheet: table from ehr Flowsheet, has GCS score
%
% OUTPUT
% qSofaTimes: table, subset of vitals and flowsheet where qSOFA conditions
% are met

%
% Olivia Alge for BCIL, February 2022.
% Matlab 2020b, Windows 10
%
    qSofaTimes = [];
    [idCol, encCol, timeCol, obsValCol, bpCol1, bpCol2, rrCol] = getColumnNames();
    
    uniqueEncounters = unique([vitals(:, {idCol, encCol}); ...
                               flowsheet(:, {idCol, encCol})]);
    
    for i = 1:size(uniqueEncounters, 1)
        iIdxFlow = (flowsheet.(idCol) == uniqueEncounters{i, idCol} & ...
                    flowsheet.(encCol) == uniqueEncounters{i, encCol});
        iIdxVitals = (vitals.(idCol) == uniqueEncounters{i, idCol} & ...
                      vitals.(encCol) == uniqueEncounters{i, encCol});
        
        temp = findThisPtQsofa(vitals(iIdxVitals, :), flowsheet(iIdxFlow, :));
        
        % Create a negative value
        if isempty(temp)
            blankRow = uniqueEncounters(i, :);
            blankRow.(timeCol) = NaT('TimeZone', vitals.(timeCol).TimeZone);
            blankRow.(bpCol1) = nan;
            blankRow.(bpCol2) = nan;
            blankRow.(rrCol) = nan;
            blankRow.(obsValCol) = nan;
            blankRow.qSofaEncoding = [0, 0, 0];
            blankRow.GCStime = NaT('TimeZone', vitals.(timeCol).TimeZone);
            blankRow.qSofaTotal = 0;
            temp = blankRow;
        end
        
        % Save to output
        qSofaTimes = [qSofaTimes; temp];
    end
    
    % Rename GCS variable
    gcsCol = strcmp(qSofaTimes.Properties.VariableNames, obsValCol);
    qSofaTimes.Properties.VariableNames{gcsCol} = 'GCS';
end

function qSofaTimes = findThisPtQsofa(patientVitalsIn, patientFlowsheet)
% DESCRIPTION
% Find datetimes where 2/3 qSOFA conditions (Respiratory rate >= 22/min,
% systolic blood pressure <= 100 mmHg, GCS < 15) are met
%
% INPUT
% patientVitals: table from ehr data vitals, only for one SepsisID
% patientFlowsheet: table from ehr Flowsheet, only for one SepsisID
%
% OUTPUT
% qSofaTimes: table, subset of patientVitals and patientFlowsheet where
% qSOFA conditions are met
%
% REQUIRES
% findRowsForQsofa(), sortTables(), findGcs.m

    %% Setup
    qSofaTimes = [];
    
    [sCol, eCol, obsCol, obsValCol, bpCol1, bpCol2, rrCol] = getColumnNames();
    outTableCols = {sCol, eCol, obsCol, bpCol1, bpCol2, rrCol};
    
    [patientVitals, patientFlowsheet] = sortTables(patientVitalsIn, ...
                                                   patientFlowsheet, obsCol);
                                               
    %% Conditions
    hasRespRate22 = patientVitals.(rrCol) >= 22;
    
    gcsRows = findGcs(patientFlowsheet);
    hasGcsLess15 = gcsRows.(obsValCol) < 15;

    isBp2Reliable = ~((patientVitals.(bpCol2) < 30) | ...
                      (patientVitals.(bpCol2) > 150));
                  
    hasSysBp100 = ((patientVitals.(bpCol2) <= 100) & isBp2Reliable);
    
    vitalsCondition = hasRespRate22 & hasSysBp100;
    
    %% Search & output creation
    try
        % qSOFA Encoding is [bp condition, gcs condition, resp rate condition]
        %% Check first for all conditions being met
        if any(vitalsCondition)
            if any(hasGcsLess15)
                qSofa3 = findRowsForQsofa(patientVitals, vitalsCondition, ...
                                                  gcsRows{hasGcsLess15, obsCol}, ...
                                                  obsCol, days(1), outTableCols);
                qSofa3 = addEncodingColumn([1, 1, 1], qSofaTimes);
                if ~isempty(qSofa3)
                    % Remove these instances from pool
                    [patientVitals, ...
                     hasSysBp100, ...
                     hasRespRate22, ...
                     foundIdx] = removeFoundRows(patientVitals, ...
                                                 vitalsCondition, qSofa3, ...
                                                 obsCol, hasSysBp100, ...
                                                 hasRespRate22);
                    vitalsCondition(foundIdx) = [];
                    qSofaTimes = [qSofaTimes; qSofa3];
                end
            end
            
            % Check for BP and RR
            qSofaTimes = [qSofaTimes; patientVitals(vitalsCondition, outTableCols)];
            qSofaTimes = addEncodingColumn([1, 0, 0], qSofaTimes);
            [patientVitals, ...
             hasSysBp100, ...
             hasRespRate22] = removeFoundRows(patientVitals, vitalsCondition, ...
                                              qSofaTimes, obsCol, hasSysBp100, ...
                                              hasRespRate22);
        end
            
        %% Next, check for BP condition being met
        if any(hasSysBp100)
            if any(hasGcsLess15)  % BP and GCS
                qSofa2 = findRowsForQsofa(patientVitals, hasSysBp100, ...
                                          gcsRows{hasGcsLess15, obsCol}, ...
                                          obsCol, days(1), outTableCols);
                qSofa2 = addEncodingColumn([1, 1, 0], qSofaTimes);
                if ~isempty(qSofa2)
                    [patientVitals, ...
                     hasSysBp100, ...
                     hasRespRate22] = removeFoundRows(patientVitals, ...
                                                      hasSysBp100, qSofa2, ...
                                                      obsCol, hasSysBp100, ...
                                                      hasRespRate22);
                    qSofaTimes = [qSofaTimes; qSofa2];
                end
            end

            % Only the BP condition is met
            bpQsofa = patientVitals(hasSysBp100, outTableCols);
            bpQsofa = addEncodingColumn([1, 0, 0], bpQsofa);
            qSofaTimes = [qSofaTimes; bpQsofa];
            [patientVitals, ...
             hasSysBp100, ...
             hasRespRate22] = removeFoundRows(patientVitals, hasSysBp100, ...
                                              qSofaTimes, obsCol, hasSysBp100, ...
                                              hasRespRate22);
        end
            
        %% Next, check for RR condition being met
        if any(hasRespRate22)
            if any(hasGcsLess15)  % RR and GCS
                qSofa2 = findRowsForQsofa(patientVitals, hasRespRate22, ...
                                              gcsRows{hasGcsLess15, obsCol}, ...
                                              obsCol, days(1), outTableCols);
                qSofa2 = addEncodingColumn([0, 1, 1], qSofa2);
                if ~isempty(qSofa2)
                    % Remove these instances from pool
                    [patientVitals, ...
                     hasSysBp100, ...
                     hasRespRate22] = removeFoundRows(patientVitals, ...
                                                      hasRespRate22, qSofa2, ...
                                                      obsCol, hasSysBp100, ...
                                                      hasRespRate22);
                    qSofaTimes = [qSofaTimes; qSofa2];
                end
            end

            % only respiratory condition
            rrQsofa = patientVitals(hasRespRate22, outTableCols);
            rrQsofa = addEncodingColumn([0, 0, 1], rrQsofa);
            qSofaTimes = [qSofaTimes; rrQsofa];
            patientVitals = removeFoundRows(patientVitals, hasRespRate22, ...
                                            qSofaTimes, obsCol, hasSysBp100, ...
                                            hasRespRate22);
        end

        %% Lastly, check for GCS condition
        if any(hasGcsLess15)
           % only GCS meets condition
            gcsQsofaTimes = findRowsForQsofa(patientVitals, ...
                                          repelem(true, size(patientVitals, 1))', ...
                                          gcsRows{hasGcsLess15, obsCol}, ...
                                          obsCol, days(1), outTableCols);
            gcsQsofaTimes = addEncodingColumn([0, 1, 0], gcsQsofaTimes);
            if ~isempty(gcsQsofaTimes)
                qSofaTimes = [qSofaTimes; gcsQsofaTimes];
            end
        end
        
        if ~isempty(qSofaTimes)
            qSofaTimes = appendGcs(qSofaTimes, gcsRows, hasGcsLess15, ...
                                   obsCol, obsValCol);
            qSofaTimes.qSofaTotal = rowfun(@sum, qSofaTimes, ...
                                       'InputVariables', 'qSofaEncoding', ...
                                       'OutputFormat', 'uniform');
            
        end
    catch ME
       if ~strcmp(ME.identifier, 'MATLAB:dimagree')
           disp('error')
       end
    end
end

%% Helper functions
function qSofaTimes = findRowsForQsofa(vitals, condition1, condition2Rows, obsCol, timeWindow, outCols)
% DESCRIPTION
% Determine if two events exist in the same time window
%
% INPUT
% vitals: vitals table from EHR
% condition1: logical, rows of vitals that meet condition
% condition2Rows: rows of vitals or flowsheets data that meet condition
% obsCol: Column name for observation date
% timeWindow: Duration, ideal time between events of condition1 and
%             condition2Rows
% outCols: cell, columns of vitals to give as output
%
% OUTPUT
% qSofaTimes: subset of vitals that meet conditions 1 and 2 in time window
%
% REQUIRES
% existsInTimeWindow.m
    qSofaTimes = [];
    inTimeWindow = existsInTimeWindow(vitals{condition1, obsCol}, ...
                                      condition2Rows, timeWindow);
    if any(inTimeWindow)
        qSofaTimes = vitals(condition1, outCols);
        qSofaTimes = qSofaTimes(inTimeWindow, :);
    end
end

function [ptVitals, ptFlowsheet] = sortTables(ptVitals, ptFlowsheet, orderCol)
% DESCRIPTION
% Sort vitals and flowsheet tables by order date
    [~, orderedByObsDate] = sort(ptVitals.(orderCol));
    ptVitals = ptVitals(orderedByObsDate, :);
    
    [~, orderedByObsDate] = sort(ptFlowsheet.(orderCol));
    ptFlowsheet = ptFlowsheet(orderedByObsDate, :);
end

function idx = getMinIdx(x)
% DESCRIPTION
% Obtain index values from MATLAB min() function
    [~, idx] = min(x);
end

function qSofaTimes = appendGcs(qSofaTimes, gcsRows, less15, obsCol, valCol)
% DESCRIPTION
% Append GCS to the vitals information in qSofaTimes
    if ~isempty(qSofaTimes)
        repOneValue = @(val) repelem(val, size(qSofaTimes, 1))';
        gcsRows = gcsRows(less15, {obsCol, valCol});
        if isempty(gcsRows)
            qSofaTimes.(valCol) = repOneValue(nan);
            qSofaTimes.GCStime = repOneValue(NaT('TimeZone', ...
                                                 qSofaTimes.(obsCol).TimeZone));
        else
            if size(gcsRows, 1) == 1
                qSofaTimes.(valCol) = repOneValue(gcsRows.(valCol));
                qSofaTimes.GCStime = repOneValue(gcsRows.(obsCol));
            else
                % Compute GCS score associated with vitals value
                diffsFun = @(x) getMinIdx(abs(x - gcsRows.(obsCol))); 
                [miIdx] = rowfun(diffsFun, qSofaTimes, 'InputVariables', obsCol);
                qSofaTimes.(valCol) = gcsRows{miIdx{:,:}, valCol};
                qSofaTimes.GCStime = gcsRows{miIdx{:,:}, obsCol};
            end
        end
    end
end

function [idCol, encCol, obsCol, obsValCol, bpCol1, bpCol2, rrCol] = getColumnNames()
% DESCRIPTION
% Assign char values to column variables
    idCol = 'SepsisID';
    encCol = 'EncID';
    obsCol = 'ObservationDate';
    obsValCol = 'ObservationValue';
    bpCol1 = 'BPSysNonInvasive';
    bpCol2 = 'BPSysInvasive';
    rrCol = 'RespiratoryRate';
end

function qsofaTable = addEncodingColumn(encoding, qsofaTable)
% DESCRIPTION
% Add encoding to table
% qSOFA Encoding is [bp condition, gcs condition, resp rate condition]
    if ~isempty(qsofaTable)
        qsofaTable.qSofaEncoding = repmat(encoding, size(qsofaTable, 1), 1);
    else
        qsofaTable = [];
    end
end

function [vitalsIn, bpBool, rrBool, foundIdx] = removeFoundRows(vitalsIn, conditionIn, qSofaIn, dateCol, bpBool, rrBool)
% DESCRIPTION
% Remove rows from vitalsIn which have already been added to qSofaIn and
% that meet conditionIn
    timeIdx = ismember(vitalsIn{:, dateCol}, qSofaIn{:, dateCol});
    foundIdx = timeIdx & conditionIn;
    vitalsIn(foundIdx, :) = [];
    bpBool(foundIdx) = [];
    rrBool(foundIdx) = [];
end