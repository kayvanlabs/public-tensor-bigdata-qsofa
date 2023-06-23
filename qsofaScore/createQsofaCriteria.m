function createQsofaCriteria(allSignalsInfo)
% DESCRIPTION
% From all instances of qSOFA, determine which criteria to choose for
% positive/negative

% Only select the first instance per encounter that meets one of these
% criteria
    outcomeCol = 'EncodedOutcome';
    totalCol = 'qSofaTotal';
    idCol = 'Sepsis_ID';
    encCol = 'Sepsis_EncID';
    timeCol = 'EventTime';
    labelCol = 'Label';
    sigStartCol = 'StartTime';
    sigEndCol = 'EndTime';
    statusCol = 'Status';
    signalDur = minutes(10);
    xtime = hours(6);
    xTotalCol = strcat(totalCol, '_', num2str(hours(xtime)), '_hrs');
    xTimeCol = strcat(timeCol, '_', num2str(hours(xtime)), '_hrs');
    xOutcomeCol = strcat(outcomeCol, '_', num2str(hours(xtime)), '_hrs');

    
    ids = unique(allSignalsInfo(:, {idCol, encCol}));  % 591 unique encounters (with signal)
    
    %% qSOFA > 0 (1) or qSOFA == 0 (0)

    % This will match based on ANY instance of ANY qSOFA criteria being met
    posCondition = allSignalsInfo.(totalCol) > 0;
    ids = unique(allSignalsInfo(posCondition, {idCol, encCol}));  % 575
    
    % This will match the first instance of qSOFA > 0 that has signals
    % available
    ids = unique(allSignalsInfo(:, {idCol, encCol}));
    posCondition = [];
    negCondition = [];
    for i = 1:size(ids, 1)
        iID = ids{i, idCol};
        iEnc = ids{i, encCol};
        iRows = ismember(allSignalsInfo{:, idCol}, iID) & ...
                ismember(allSignalsInfo{:, encCol}, iEnc);
        iRows = sortrows(allSignalsInfo(iRows, :), timeCol, 'ascend');
        if any(iRows{:, totalCol} >= 1)
            iQsofa1 = find(iRows{:, totalCol} >= 1);
            hasSignalsAvailable = iQsofa1(strcmp(iRows{iQsofa1, statusCol}, ""));
            if any(hasSignalsAvailable)
                firstAvailable = hasSignalsAvailable(1:2);
                posCondition = [posCondition; iRows(firstAvailable, :)];
            end
        else
            negCondition = [negCondition; iRows];
        end
    end
    
    % This will match the first instance of qSOFA > 0 and will only keep it
    % if it has signals available
    ids = unique(allSignalsInfo(:, {idCol, encCol}));
    posCondition = [];
    negCondition = [];
    for i = 1:size(ids, 1)
        iID = ids{i, idCol};
        iEnc = ids{i, encCol};
        iRows = ismember(allSignalsInfo{:, idCol}, iID) & ...
                ismember(allSignalsInfo{:, encCol}, iEnc);
        iRows = sortrows(allSignalsInfo(iRows, :), timeCol, 'ascend');
        if any(iRows{:, totalCol} >= 1)
            iQsofa1 = iRows{:, totalCol} >= 1;
            firstQsofa1 = find(iQsofa1, 1);
            if strcmp(iRows{firstQsofa1, statusCol}, "")
                firstQsofa1 = [firstQsofa1, firstQsofa1 + 1];
                posCondition = [posCondition; iRows(firstQsofa1, :)];
            end
        else
            negCondition = [negCondition; iRows];
        end
    end

    % This searches for instances of qSOFA == 1 that later progresses to
    % qSOFA > 1
    ids = unique(allSignalsInfo(:, {idCol, encCol}));
    posCondition = zeros(size(allSignalsInfo, 1), 1);
    negCondition1 = zeros(size(allSignalsInfo, 1), 1);
    negCondition0 = zeros(size(allSignalsInfo, 1), 1);
    iRowsEnum = (1:size(allSignalsInfo, 1))';
    for i = 1:size(ids, 1)
        iID = ids{i, idCol};
        iEnc = ids{i, encCol};
        iRows = ismember(allSignalsInfo{:, idCol}, iID) & ...
                ismember(allSignalsInfo{:, encCol}, iEnc);
        uTotals = unique(allSignalsInfo{iRows, totalCol}, 'stable');
        if length(uTotals) > 1
            iqsofa1 = iRowsEnum((allSignalsInfo{:, totalCol} == 1) & iRows);
            iqsofaGT1 = iRowsEnum((allSignalsInfo{:, totalCol} > 1) & iRows);
            % Find first instance of qSOFA == 1 that occurs before an
            % instance of qSOFA > 1
            iqsofaCompare = iqsofa1 < iqsofaGT1';
            firstQsofa1 = iqsofa1(find(sum(iqsofaCompare, 2), 1));
            posCondition(firstQsofa1) = 1;
        % All qSOFA totals for this encounter are 0
        elseif all(uTotals == 0)
            negCondition0(iRows) = 1;  % 16 for 6hr
        % qSOFA never increases above 1
        elseif max(uTotals) == 1
            negCondition1(iRows) = 1;  % 250 for 6hr
        end
    end
    posCondition = logical(posCondition);
    negCondition = logical(negCondition1);
    [idsPos, idxPos] = unique(allSignalsInfo(posCondition, {idCol, encCol}));  % 265 for 6hr
    [idsNeg, idxNeg] = unique(allSignalsInfo(negCondition, {idCol, encCol}));
    posCondition = iRowsEnum(posCondition);
    negCondition = iRowsEnum(negCondition);
    [posCondition, posCondition + 1];
    % Get EKG and Art Line Rows
    idxPos = posCondition(idxPos);
    idxPos = reshape([idxPos, idxPos + 1]', [], 1);
    idxNeg = negCondition(idxNeg);
    idxNeg = reshape([idxNeg, idxNeg + 1]', [], 1);
    instancesPos = allSignalsInfo(idxPos, :);
    instancesPos.Label = repelem(true, size(instancesPos, 1))';
    instancesNeg = allSignalsInfo(idxNeg, :);
    instancesNeg.Label = repelem(false, size(instancesNeg, 1))';
    allInstances = [instancesPos; instancesNeg];


end
function void()
%% BP meets qSOFA criteria (1) or does not (0)
% Encoding is [BP condition, GCS Condition, RR Condition], so match first
% index
    bpIndex = 1;
    % This will match based on ANY instance of ANY qSOFA criteria being met
    % and then find blood pressure matches
    
    
    
    % This ignores instances of qSOFA == 1 for respiratory rate or GCS 
    % (searches for the first instance of BP condition being met before
    % determining positive/negative)
    posCondition = strcmp(extract(allSignalsInfo.(outcomeCol), bpIndex), '1');
    ids = unique(allSignalsInfo(posCondition, {idCol, encCol}));  % 436
end

function void1()

end

function void2()
    %% qSOFA >= 2 (1) or qSOFA < 2 (0)

    % This will assign negative to any instance of qSOFA < 2 before
    % determining positive for qSOFA >= 2
    
    % This will assign positive to an instance of qSOFA >= 2 that has an
    % instance of qSOFA == 1 that occurs X hours before. 
    % It will assign negative to an instance of qSOFA <= 1 that has an
    % instance of qSOFA == 1 that occurs X hours before AND DOES NOT occur
    % after a positive instance.
    % This requires allSignalsInfo to have a status column
    ids = unique(allSignalsInfo(:, {idCol, encCol}));
    posCondition = [];
    negCondition = [];
    for i = 1:size(ids, 1)
        iID = ids{i, idCol};
        iEnc = ids{i, encCol};
        iRows = ismember(allSignalsInfo{:, idCol}, iID) & ...
                ismember(allSignalsInfo{:, encCol}, iEnc);
        iRows = sortrows(allSignalsInfo(iRows, :), timeCol, 'ascend');
        % See if any instances of qsofa >= 2
        if any(iRows{:, totalCol} >= 2)
            iQsofa2 = iRows{:, totalCol} >= 2;
            firstQsofa2 = find(iQsofa2, 1);
            % See if there is an instance where qSOFA is 1 and has
            % available signal xTime before
            iRowsWithSignalForQ1 = iRows{1:firstQsofa2, totalCol} == 1 & ...
                                   strcmp(iRows{1:firstQsofa2, statusCol}, "");
            temp = 1:size(iRows, 1);
            iRowsWithSignalForQ1 = temp(iRowsWithSignalForQ1);
            if any(iRowsWithSignalForQ1)
                bufferXearly = xtime - hours(1);
                bufferXlate = xtime + hours(1);
                predictionSignalStart = iRows{firstQsofa2, timeCol} - xtime - signalDur;
                predictionSignalEnd = iRows{firstQsofa2, timeCol} - xtime;
                % If by some miracle, times line up perfectly
                if any(iRows{iRowsWithSignalForQ1, timeCol} == predictionSignalEnd)
                    matchedIdx = iRows{iRowsWithSignalForQ1, timeCol} == predictionSignalEnd;
                    iSignal = iRows(iRowsWithSignalForQ1(matchedIdx), :);
                    iSignal.(xTotalCol) = repelem(iRows{firstQsofa2, totalCol}, size(iSignal, 1))';
                    iSignal.(xTimeCol) = repelem(iRows{firstQsofa2, timeCol}, size(iSignal, 1))';
                    iSignal.(xOutcomeCol) = repelem(iRows{firstQsofa2, outcomeCol}, size(iSignal, 1))';
                    iSignal.diff = repelem(minutes(0), size(iSignal, 1))';
                    posCondition = [posCondition; iSignal];
                else
                    % Find closest possible match
                    [timeDiff, idx] = min(abs(predictionSignalEnd - iRows{iRowsWithSignalForQ1, timeCol}));
                    idx = iRowsWithSignalForQ1(idx);
                    % If within buffer region, assume signal can be added
                    if (timeDiff < (xtime - bufferXearly)) && (timeDiff < (xtime + bufferXlate))
                        if (iRows{idx, sigStartCol} <= predictionSignalStart) && (iRows{idx, sigEndCol} >= predictionSignalEnd)
                            iSignal = iRows(idx:idx+1, :);
                            iSignal.(xTotalCol) = repelem(iRows{firstQsofa2, totalCol}, size(iSignal, 1))';
                            iSignal.(xTimeCol) = repelem(iRows{firstQsofa2, timeCol}, size(iSignal, 1))';
                            iSignal.(xOutcomeCol) = repelem(iRows{firstQsofa2, outcomeCol}, size(iSignal, 1))';
                            iSignal.predictionSignalStart = repelem(predictionSignalStart, size(iSignal, 1))';
                            iSignal.predictionSignalEnd = repelem(predictionSignalEnd, size(iSignal, 1))';
                            iSignal.diff = repelem(timeDiff, size(iSignal, 1))';
                            posCondition = [posCondition; iSignal];
                        end
                    end
                end
            end
            
        else  % instances of (qsofa 1) -> (X time) -> (qsofa < 2)
            bufferXlate = xtime * 2 + hours(24);
            iRowsEnum = 1:size(iRows, 1);
            jArr = iRowsEnum((iRows{:, totalCol}) == 1 & strcmp(iRows{:, statusCol}, ""));
            for j = jArr
                jPossibleStart = iRows(j, :);
                jPossibleEnds = iRowsEnum(iRows{:, timeCol} >= (jPossibleStart.(timeCol) + xtime) & ...
                                          iRows{:, timeCol} < (jPossibleStart.(timeCol) + xtime + bufferXlate));
                if any(jPossibleEnds)
                    iSignal = iRows(j:j + 1, :);
                    jEnd = jPossibleEnds(1);
                    iSignal.(xTotalCol) = repelem(iRows{jEnd, totalCol}, size(iSignal, 1))';
                    iSignal.(xTimeCol) = repelem(iRows{jEnd, timeCol}, size(iSignal, 1))';
                    iSignal.(xOutcomeCol) = repelem(iRows{jEnd, outcomeCol}, size(iSignal, 1))';
                    iSignal.diff = iSignal.(xTimeCol) - iSignal.(timeCol);
                    negCondition = [negCondition; iSignal]; 
                    break
                end                
            end
        end
    end
    
    % This searches for the first instance of qSOFA >= 2 before determining
    % positive or negative
    posCondition = allSignalsInfo.(totalCol) >= 2;
    ids = unique(allSignalsInfo(posCondition, {idCol, encCol}));  % 325 for 6hr, 546 for 0hr

end