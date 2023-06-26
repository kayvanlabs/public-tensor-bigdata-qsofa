function [featureName,encodedTemp,featureTime]=encodeTemp(row,lr,prevVal,prevTime)
    featureName='Temperature';
    obsCol = 'ObservationDate';
    noTime = NaT(1, 'TimeZone', lr{row, obsCol}.TimeZone);
    featureTime = noTime;
    %convert value
    currTemp=lr{row,'Temperature'};
    if ~isnumeric(currTemp)
        currTemp = str2double(currTemp);
    end
    %validate temperature, perform conversions
    if ~isnan(currTemp)
        featureTime = lr{row, obsCol};
        %first convert to celsius if necessary
        %celsius, do nothing
        if currTemp >=26 && currTemp <=44
        %fahrenheit, covert
        elseif currTemp >=78.8 && currTemp < 111.2
            currTemp = (currTemp-32)*(5/9);
        %invalid temperature
        else
            currTemp=NaN;
            featureTime = noTime;
        end
        %adjust temperature based on the source to be oral temp, assume unknown is oral
        tempRoute =lr{row,'TemperatureRoute'}{1};
        %core administered
        if any(strfind(tempRoute,"Core")) > 0 || any(strfind(tempRoute,"Foley")) > 0 || any(strfind(tempRoute,"Rectal")) > 0
            %core temps are .3-.6 degrees C higher than oral
            currTemp=currTemp-.45;
        elseif any(strfind(tempRoute,"Axillary")) > 0 || any(strfind(tempRoute,"Tympanic")) > 0 || any(strfind(tempRoute,"Temporal")) > 0
            %these temps are .3-.6 degrees C lower than oral
            currTemp=currTemp+.45;
        end
    end
    
    %decide how to handle vital
    if isnan(currTemp)
        if ~isnan(prevVal)
            %carry forward
            currTemp = prevVal;
            featureTime = prevTime;
        end
    end
    encodedTemp = currTemp;
end
