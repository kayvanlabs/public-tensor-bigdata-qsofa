function [featureName,encodedSpO2,featureTime]=encodeSpO2(row,lr,prevVal, prevTime)
    featureName='SpO2';
    obsCol = 'ObservationDate';
    noTime = NaT(1, 'TimeZone', lr{row, obsCol}.TimeZone);
    
    %convert value
    currSpO2=lr{row,featureName};
    featureTime = noTime;
    if ~isnumeric(currSpO2)
        currSpO2 = str2double(currSpO2);
    end
    %validate SpO2
    if ~isnan(currSpO2)
        if currSpO2 >100 || currSpO2 <80
            currSpO2=NaN;
            featureTime = noTime;
        else
            featureTime = lr{row, obsCol};
        end
    end
    
    %decide how to handle vital
    if isnan(currSpO2)
        if ~isnan(prevVal)
            %carry forward
            currSpO2 = prevVal;
            featureTime = prevTime; 
        end
    end

    encodedSpO2=currSpO2;
end
