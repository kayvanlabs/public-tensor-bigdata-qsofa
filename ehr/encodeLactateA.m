function [featureName,encodedLactate]=encodeLactateA(row,lr)
    featureName='Lactate';
    %ordinal encoding for lactate levels    
    encodedLactate = nan;
 
    %convert value if needed
    lactateLevel = lr{row, 'VALUE'};
    if ~isnumeric(lactateLevel)
        lactateLevel=str2double(lactateLevel);
    end
    
    %if not NaN, encode
    % 10.1097/01.TA.0000133577.25793.E5 notes associating higher lactate
    % levels with mortality, but doesn't address low lactate levels
    if ~isnan(lactateLevel)
        if lactateLevel < .5
            %low
            encodedLactate = 2;                
        elseif lactateLevel <= 1.6
            %normal
            encodedLactate = 1;
        elseif lactateLevel <= 4.0
            %high
            encodedLactate = 3;
        else
            %critical
            encodedLactate = 4;
        end
    end
end
 