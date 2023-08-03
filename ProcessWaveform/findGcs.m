function gcsOut = findGcs(flowsheet)
% DESCRIPTION
% Find instances of the Glasgow Coma Scale in the flowsheet and return
% these rows, casting the scale value to a double

    % test1 = find(contains(flowsheet.ObservationName, 'GCS'));
    % test2 = find(contains(flowsheet.ObservationName, 'Glasgow', 'IgnoreCase', true));
    % 'GCS Score', 'UM R GLASGOW COMA SCALE 5+ - TOTAL [GCS Total]'
    termCol = 'ObservationTermID';
    valueCol = 'ObservationValue';
    gcsKeys = [6898, 355405, 307953];
    gcsIdx = ismember(flowsheet.(termCol), gcsKeys);
    gcsOut = flowsheet(gcsIdx, :);
    gcsOut.(valueCol) = str2double(gcsOut.(valueCol));
end