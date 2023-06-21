function [featureName,encodedHR]=encodeHR(row,lr,prevVal)
    featureName='HR';
 
    %convert value
    currHR=lr{row,'HeartRate'};
    if ~isnumeric(currHR)
        currHR = str2double(currHR);
    end
    %validate HR
    if ~isnan(currHR)
        if currHR >300 || currHR <25
            currHR=NaN;
        end
    end
    %decide how to handle vital
    if isnan(currHR)
        if isnan(prevVal)
            %set to default
            currHR = 80;
        else
            %carry forward
            currHR=prevVal;
        end
    end
    encodedHR=currHR;
end
 