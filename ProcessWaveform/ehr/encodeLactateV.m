function [featureName,encodedLactate]=encodeLactateV(row,lr)
    featureName='Lactate';
    %one-hot encoding for lactate levels    
    encodedLactate=nan;
 
    %convert value
    lactateLevel=lr{row,'VALUE'};
    if ~isnumeric(lactateLevel)
        lactateLevel = str2double(lactateLevel);
    end
    %if not NaN, encode
    if ~isnan(lactateLevel)
        if lactateLevel < .5
            %low
            encodedLactate = 1;
        elseif lactateLevel <= 2.2
            %normal
            encodedLactate = 2;
        elseif lactateLevel <= 4.0
            %high
            encodedLactate = 3;
        else
            %critical
            encodedLactate = 4;
        end
    end
end
 