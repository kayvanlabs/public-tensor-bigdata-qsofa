function doesExistInWindow = existsInTimeWindow(time1, time2, winDuration)
% DESCRIPTION
% Determine if datetime time1 and datetime time2 exist within winDuration
% of each other
    doesExistInWindow = logical(sum(abs(time1 - time2') < winDuration, 2));
end