function [featureName,encodedSodium]=encodeSodium(row,lr)
    featureName='Sodium';
    %one-hot encoding for sodium levels    
    encodedSodium=nan;
 
    %convert value
    sodiumLevel=lr{row,'VALUE'};
    if ~isnumeric(sodiumLevel)
        sodiumLevel = str2double(sodiumLevel);
    end
    %if not NaN, encode
    % 10.1016/j.ejim.2020.10.003
    % severity increases normal, low, high, critical
    if ~isnan(sodiumLevel)
        if sodiumLevel < 136
            %low
            encodedSodium = 2;                
        elseif sodiumLevel <= 146
            %normal
            encodedSodium = 1;
        elseif sodiumLevel <= 155
            %high
            encodedSodium = 3;
        else
            %critical
            encodedSodium = 4;
        end
    end
end
 