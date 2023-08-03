function [featureName,encodedHematocrit]=encodeHematocrit(row,lr)
    featureName='HCT';
    %one-hot encoding for hematocrit levels    
    encodedHematocrit=nan;
    
    gender = lr{row,'Gender'};
    %Hematocrit Male
    if strcmp(gender,'M')
        %Critical <22
        low = 22;
        %Low 22-39
        normal = 40;
        %Normal 40-50
        high = 51;
        %High >50
    %Hematocrit Female
    else
        %Critical <22
        low = 22;
        %Low 22-35
        normal = 36;
        %Normal 36-48
        high = 49;
        %High >48
    end

    %encode HCT
    % 10.1371/journal.pone.0265758
    % Severity increases high, normal, low, critical
    hctLevel=lr{row,'VALUE'};
    if ~isnumeric(hctLevel)
        hctLevel=str2double(hctLevel);
    end
    %if not NaN, encode and add to result table 
    if ~isnan(hctLevel)
        if hctLevel < low
            %critical
            encodedHematocrit = 4;
        elseif hctLevel < normal
            %low
            encodedHematocrit = 3;
        elseif hctLevel < high
            %normal
            encodedHematocrit = 1;
        else
            %high
            encodedHematocrit = 2;
        end
    end

end
 