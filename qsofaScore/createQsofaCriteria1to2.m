function [posCondition, negCondition] = createQsofaCriteria1to2(allSignalsInfo, gapDur, signalDur)
% DESCRIPTION
% From all instances of qSOFA, determine which criteria to choose for
% positive/negative
    outcomeCol = 'EncodedOutcome';
    totalCol = 'qSofaTotal';
    idCol = 'Sepsis_ID';
    encCol = 'Sepsis_EncID';
    timeCol = 'EventTime';
    labelCol = 'Label';
    sigStartCol = 'StartTime';
    sigEndCol = 'EndTime';
    statusCol = 'Status';
    xTotalCol = strcat(totalCol, '_', num2str(hours(gapDur)), '_hrs');
    xTimeCol = strcat(timeCol, '_', num2str(hours(gapDur)), '_hrs');
    xOutcomeCol = strcat(outcomeCol, '_', num2str(hours(gapDur)), '_hrs');

    isequalwithequalnans
    
    ids = unique(allSignalsInfo(:, {idCol, encCol}));  % 591 unique encounters (with signal)
    
   %% qSOFA >= 2 (1) or qSOFA < 2 (0)
    % This will assign positive to an instance of qSOFA >= 2 that has an
    % instance of qSOFA == 1 that occurs <gapDuration>  before. 
    % It will assign negative to an instance of qSOFA <= 1 that has an
    % instance of qSOFA == 1 that occurs <gapDuration> before AND DOES NOT occur
    % after a positive instance.
    % This requires allSignalsInfo to have a status column
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
                bufferXearly = gapDur - hours(1);
                bufferXlate = gapDur + hours(1);
                predictionSignalStart = iRows{firstQsofa2, timeCol} - gapDur - signalDur;
                predictionSignalEnd = iRows{firstQsofa2, timeCol} - gapDur;
                % If times line up perfectly
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
                    if (timeDiff < (gapDur - bufferXearly)) && (timeDiff < (gapDur + bufferXlate))
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
            bufferXlate = gapDur * 2 + hours(24);
            iRowsEnum = 1:size(iRows, 1);
            jArr = iRowsEnum((iRows{:, totalCol}) == 1 & strcmp(iRows{:, statusCol}, ""));
            for j = jArr
                jPossibleStart = iRows(j, :);
                jPossibleEnds = iRowsEnum(iRows{:, timeCol} >= (jPossibleStart.(timeCol) + gapDur) & ...
                                          iRows{:, timeCol} < (jPossibleStart.(timeCol) + gapDur + bufferXlate));
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
    posCondition.(labelCol) = repelem(1, size(posCondition, 1))';
    negCondition.(labelCol) = repelem(0, size(negCondition, 1))';
end