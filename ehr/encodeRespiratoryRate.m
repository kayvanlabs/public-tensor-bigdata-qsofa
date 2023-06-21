function [featureName,encodedRespiratoryRate]=encodeRespiratoryRate(row,lr,prevVal)
    featureName='RespiratoryRate';
 
    %convert value
    currRespiratoryRate=lr{row,'RespiratoryRate'};
    if ~isnumeric(currRespiratoryRate)
        currRespiratoryRate = str2double(currRespiratoryRate);
    end
    %validate Respiratory Rate
    if ~isnan(currRespiratoryRate)
        if currRespiratoryRate >80 || currRespiratoryRate <1
            currRespiratoryRate=NaN;
        end
    end
    %decide how to handle vital
    if isnan(currRespiratoryRate)
        if isnan(prevVal)
            %set to default
            currRespiratoryRate = 14;
        else
            %carry forward
            currRespiratoryRate=prevVal;
        end
    end
    encodedRespiratoryRate=currRespiratoryRate;
end
 