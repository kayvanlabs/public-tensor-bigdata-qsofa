function tableNoOverlaps = removeOverlappingIds(tableIn, idCol, encCol, obsCol, doUseOnlyUnique)
% DESCRIPTION
% Remove overlapping IDs from among multiple years by only keeping earliest
% instance of event
% TODO: log both NaTs and first events for all yeares
%
% INPUT
%   tableIn: table of event instances
%   idCol: string, column of tableIn that stores SepsisID
%   encCol: string, column of tableIn that stores EncID
%   obsCol: string, column of tableIn that stores event time
%   useOnlyUnique: logical, whether to loop per ID or ID+EncID
%
% OUTPUT
%   tableNoOverlaps: tableIn with the earliest instance of obsCol per
%   idCol / (idCol + encCol)

    % Initialize output
    tableNoOverlaps = [];
    
    % Set up loop variable
    if doUseOnlyUnique
        ids = unique(tableIn.(idCol));
        selectCondition = @(x) tableIn.(idCol) == ids(x);
    else
        if ~strcmp(class(tableIn.(encCol)), 'double')
            tableIn.(encCol) = str2double(tableIn.(encCol));
        end
        ids = unique(tableIn(:, [idCol, encCol]));
        selectCondition = @(x) tableIn.(idCol) == ids{x, idCol} & ...
                               tableIn.(encCol) == ids{x, encCol};
    end
    
    % Loop
    for i = 1:size(ids, 1)
        iData = tableIn(selectCondition(i), :);
        if size(iData, 1) > 1
            if all(isnat(iData.(obsCol)))  % all instances negative
                tableNoOverlaps = [tableNoOverlaps; iData(1, :)];
            %elseif sum(~isnat(iData.(obsCol))) == 1  % only 1 positive instance
            %    tableNoOverlaps = [tableNoOverlaps; iData];
            else  % mixed, pick earliest
                [~, idx] = min(iData.(obsCol));
                tableNoOverlaps = [tableNoOverlaps; iData(idx, :)];
            end
        else
            tableNoOverlaps = [tableNoOverlaps; iData];
        end
    end
end