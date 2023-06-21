function [featureName,encodedMAP]=encodeMAP(row,lr,prevVal)
    featureName='MAP';
 
    %convert value
    currNonInvMAP=lr{row,'BPMeanNonInvasive'};
    if ~isnumeric(currNonInvMAP)
        currNonInvMAP = str2double(currNonInvMAP);
    end
    currInvMAP=lr{row,'BPMeanInvasive'};
    if ~isnumeric(currInvMAP)
        currInvMAP = str2double(currInvMAP);
    end
    
    %choose higher MAP if both available
    if ~isnan(currNonInvMAP) && ~isnan(currInvMAP)
        currMAP = max(currNonInvMAP,currInvMAP);
    elseif ~isnan(currNonInvMAP)
        currMAP = currNonInvMAP;
    elseif ~isnan(currInvMAP)
        currMAP = currInvMAP;
    else
        currMAP = NaN;
    end
    %decide how to handle vital
    if isnan(currMAP)
        if isnan(prevVal)
            %set to default
            currMAP = 82.5;
        else
            %carry forward
            currMAP=prevVal;
        end
    end
    encodedMAP=currMAP;
end
 