function [featureName,encodedSpO2]=encodeSpO2(row,lr,prevVal)
    featureName='SpO2';
 
    %convert value
    currSpO2=lr{row,featureName};
    if ~isnumeric(currSpO2);
        currSpO2 = str2double(currSpO2);
    end
    %validate SpO2
    if ~isnan(currSpO2)
        if currSpO2 >100 || currSpO2 <80
            currSpO2=NaN;
        end
    end
    %decide how to handle vital
    if isnan(currSpO2)
        if isnan(prevVal)
            %set to default
            currSpO2 = 95.5;
        else
            %carry forward
            currSpO2=prevVal;
        end
    end
    encodedSpO2=currSpO2;
end
 