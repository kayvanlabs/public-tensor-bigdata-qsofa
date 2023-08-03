function [featureName,encodedPlatelets]=encodePlatelets(row,lr)
    featureName='PLT';
    % encoding for platelet count  
    encodedPlatelets=nan;
 
    %convert value
    plateletLevel=lr{row,'VALUE'};
    if ~isnumeric(plateletLevel)
        plateletLevel = str2double(plateletLevel);
    end
    %if not NaN, encode
    % severity increases high, normal, low, critical
    if ~isnan(plateletLevel)
        if plateletLevel < 50
            %critical
            encodedPlatelets = 4;                
        elseif plateletLevel < 150
            %low
            encodedPlatelets = 3;                
        elseif plateletLevel <= 400
            %normal
            encodedPlatelets = 1;
        else
            %high
            encodedPlatelets = 2;
        end
    end
end
 