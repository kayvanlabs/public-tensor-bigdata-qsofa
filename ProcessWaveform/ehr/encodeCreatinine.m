function [featureName,encodedCreatinine]=encodeCreatinine(row,lr)
    featureName='Creatinine';
    %encoding for creatinine levels    
    encodedCreatinine=nan;

    gender = lr{row,'Gender'};
    %Creatinine male
    if strcmp(gender,'M')
        %Low <0.70
        low=.7;
        %Normal 0.70-1.30
        normal=1.3;
        %High 1.31-2.00
        high=2;
        %Critical >2.00
    %Creatinine female
    else
        %Low <0.50
        low=.5;
        %Normal 0.50-1.00
        normal=1;
        %High 1.01-2.00
        high=2;
        %Critical >2.00
    end
    %encode creatinine
    % 10.1371/journal.pone.0183156
    % least to most severe is normal, low, high, critical
    creatinineLevel=lr{row,'VALUE'};
    if ~isnumeric(creatinineLevel)
        creatinineLevel=str2double(creatinineLevel);
    end
    %if not NaN, encode and add to result table 
    if ~isnan(creatinineLevel)
        if creatinineLevel < low
            %low
            encodedCreatinine = 2;
        elseif creatinineLevel <= normal
            %normal
            encodedCreatinine = 1;
        elseif creatinineLevel <= high
            %high
            encodedCreatinine = 3;
        else
            %critical
            encodedCreatinine = 4;
        end
    end

end
 