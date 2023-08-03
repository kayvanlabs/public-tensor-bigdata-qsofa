function [featureName,encodedWBC]=encodeWBC(row,lr)
    featureName='WBC';
    %encoding for WBC count  
    encodedWBC=nan;
 
    %convert value
    WBCLevel=lr{row,'VALUE'};
    if ~isnumeric(WBCLevel)
        WBCLevel = str2double(WBCLevel);
    end
    %if not NaN, encode
    % 10.1515/cclm-2014-0210
    % Severity increases normal, low, high, critical
    if ~isnan(WBCLevel)
        if WBCLevel < 4
            %low
            encodedWBC = 2;                
        elseif WBCLevel <= 10
            %normal
            encodedWBC = 1;
        elseif WBCLevel <= 20
            %high
            encodedWBC = 3;
        else
            %critical
            encodedWBC = 4;
        end
    end
end
 