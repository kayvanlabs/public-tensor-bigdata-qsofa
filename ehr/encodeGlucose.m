function [featureName,encodedGlucose]=encodeGlucose(row,lr)
    featureName='Glucose';
    % encoding for glucose levels    
    encodedGlucose=nan;
 
    %convert value
    glucoseLevel=lr{row,'VALUE'};
    if ~isnumeric(glucoseLevel)
        glucoseLevel=str2double(glucoseLevel);
    end
    
    %if not NaN, encode
    % 10.2174/138161208784980563 hypoglycemia may be an effect of insulin,
    % so increasing severity is normal, low, high, critical
    if ~isnan(glucoseLevel)
        if glucoseLevel < 40
            %critical
            encodedGlucose = 4;
        elseif glucoseLevel < 70
            %low
            encodedGlucose = 2;                
        elseif glucoseLevel <= 180
            %normal
            encodedGlucose = 1;
        else
            %high
            encodedGlucose = 3;
        end
    end
end
 