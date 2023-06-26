function [featureName,encodedHemoglobin]=encodeHemoglobin(row,lr)
    featureName='Hgb';
    %one-hot encoding for hemoglobin levels    
    encodedHemoglobin=nan;

    gender = lr{row,'Gender'}; 
    %Hemoglobin Male
    if strcmp(gender,'M')
        %Critical <7.0
        low = 7.0;
        %Low 7.0-13.4
        normal = 13.4;
        %Normal 13.5-17.0
        high = 17;
        %High >17.0
    %Hemoglobin Female
    else
        %Critical <7.0
        low = 7.0;
        %Low 7.0-11.9
        normal = 11.9;
        %Normal 12.0-16.0
        high = 16.0;
        %High >16.0
    end

    %encode Hgb
    % 10.1186/s12879-016-1882-7
    % Severity increases high, normal, low, critical
    hgbLevel=lr{row,'VALUE'};
    if ~isnumeric(hgbLevel)
        hgbLevel = str2double(hgbLevel);
    end
    %if not NaN, encode and add to result table 
    if ~isnan(hgbLevel)
        if hgbLevel < low
            %critical
            encodedHemoglobin = 4;
        elseif hgbLevel <= normal
            %low
            encodedHemoglobin = 3;
        elseif hgbLevel <= high
            %normal
            encodedHemoglobin = 1;
        else
            %high
            encodedHemoglobin = 2;
        end
    end

end
 