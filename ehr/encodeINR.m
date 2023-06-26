function [featureName,encodedINR]=encodeINR(row,lr)
    featureName='INR';
    % encoding for INR  
    encodedINR=nan;
 
    %convert value
    INRLevel=lr{row,'VALUE'};
    if ~isnumeric(INRLevel)
        INRLevel = str2double(INRLevel);
    end
    %if not NaN, encode
    % 10.12998/wjcc.v9.i25.7405
    % severity increases low, normal, high, critical
    if ~isnan(INRLevel)
        if INRLevel < .9
            %low
            encodedINR = 2;                
        elseif INRLevel <= 1.2
            %normal
            encodedINR = 1;
        elseif INRLevel <= 2.0
            %high
            encodedINR = 3;
        else
            %critical
            encodedINR = 4;
        end
    end
end
 