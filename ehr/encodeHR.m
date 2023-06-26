function [featureName,encodedHR,featureTime]=encodeHR(row,lr,prevVal, prevTime)
    featureName='HR';
    obsCol = 'ObservationDate';
    noTime = NaT(1, 'TimeZone', lr{row, obsCol}.TimeZone);
    %convert value
    currHR=lr{row,'HeartRate'};
    featureTime = noTime;
    if ~isnumeric(currHR)
        currHR = str2double(currHR);
    end
    %validate HR
    if ~isnan(currHR)
        if currHR >300 || currHR <25
            currHR=NaN;
            featureTime = noTime;
        else
            featureTime = lr{row, obsCol};
        end
    end
    
    %decide how to handle vital
    if isnan(currHR)
        if ~isnan(prevVal)
            %carry forward
            currHR=prevVal;
            featureTime = prevTime;
        end
    end
    encodedHR=currHR;
end


 