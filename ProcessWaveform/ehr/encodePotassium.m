function [featureName,encodedPotassium]=encodePotassium(row,lr)
    featureName='Potassium';
    %one-hot encoding for potassium levels    
    encodedPotassium=zeros(1,4);
 
    %convert value
    potassiumLevel=lr{row,'VALUE'};
    if ~isnumeric(potassiumLevel)
        potassiumLevel = str2double(potassiumLevel);
    end
    %if not NaN, encode
    % Low potassium can be indicative of disease, so this gets high
    % priority
    % Severity increases normal, high, low, critical?
    if ~isnan(potassiumLevel)
        if potassiumLevel < 3.5
            %low
            encodedPotassium = 3;                
        elseif potassiumLevel <= 5
            %normal
            encodedPotassium = 1;
        elseif potassiumLevel <= 6.0
            %high
            encodedPotassium = 2;
        else
            %critical
            encodedPotassium = 4;
        end
    end
end
 