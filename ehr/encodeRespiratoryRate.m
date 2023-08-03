function [featureName,encodedRespiratoryRate,featureTime]=encodeRespiratoryRate(row,lr,prevVal,prevTime)
    featureName='RespiratoryRate';
    obsCol = 'ObservationDate';
    noTime = NaT(1, 'TimeZone', lr{row, obsCol}.TimeZone);
    featureTime = noTime;
    %convert value
    currRespiratoryRate=lr{row,'RespiratoryRate'};
    if ~isnumeric(currRespiratoryRate)
        currRespiratoryRate = str2double(currRespiratoryRate);
    end
    %validate Respiratory Rate
    if ~isnan(currRespiratoryRate)
        if currRespiratoryRate >80 || currRespiratoryRate <1
            currRespiratoryRate=NaN;
            featureTime = noTime;
        else
            featureTime = lr{row, obsCol};
        end
    end
    %decide how to handle vital
    if isnan(currRespiratoryRate)
        if ~isnan(prevVal)
            %carry forward
            currRespiratoryRate=prevVal;
            featureTime=prevTime;
        end
    end
    encodedRespiratoryRate=currRespiratoryRate;
end
 
