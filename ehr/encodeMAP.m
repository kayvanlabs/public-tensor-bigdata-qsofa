function [featureName,encodedMAP,featureTime]=encodeMAP(row,lr,prevVal, prevTime)
    featureName='MAP';
    obsCol = 'ObservationDate';
    noTime = NaT(1, 'TimeZone', lr{row, obsCol}.TimeZone);
    featureTime = lr{row, 'ObservationDate'};
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
        featureTime = noTime;
    end
    
        %decide how to handle vital
    if isnan(currMAP)
        if ~isnan(prevVal)
            %carry forward
            currMAP = prevVal;
            featureTime = prevTime;
        end
    end
    
    encodedMAP=currMAP;
end
 