function outputTable = find_x_days_out(nDaysOut, output24, intubation)
% DESCRIPTION
% Find intubation status nDaysOut days from the EKG signals present in
% output24
%
% REQUIRES
%   output24 has the columns:
%       'thisDate': datetime, indicates current date
%       'lastDay': datetime, last day for which intubation data exists, 
%                  regardless of intubation status
%       'SepsisID': numeric, column to identify individuals
%   intubation has the columns:
%       'SepsisID': numeric, column to identify individuals
%       'ActivityDate': datetime, indicates current date
%       'Intubated_YN_Numeric': numeric or logical, indicates intubation
%                               tatus on ActivityDate
%
% INPUT
%   nDaysOut: numeric, number of days in the future from the current date
%             (output23.thisDate) from which to find intubation status
%   output24: table, output from find_24_hour_signal_data_for_intubation()   
%   intubation: table, from ehrStruct. Contains intubation status
%
% OUTPUT
%   outputTable: subset of output24 that has a row in intubation
%                corresponding to nDaysOut in the future, and has the
%                additional columns 'outcomeDate' and 'intubatedAtOutcome',
%                which are datetime and numeric, respectively. They give
%                information on whether or not the individual was intubated
%                on outcomeDate.
%
% Matlab 2019a, Windows 10
% Olivia Alge

    % First, find if intubation status is avaialable x days out from the
    % EKG date
    nDaysOutVec = output24.thisDate + days(nDaysOut);
    % Using yyyymmdd to check for 24-hour differences because Matlab won't
    % match columns that differ by one day if the hours are different (e.g.
    % daylight savings time). 
    simpleDaysOut = yyyymmdd(nDaysOutVec);
    daysAvailableIdx = simpleDaysOut <= yyyymmdd(output24.lastDay);
    
    output24 = output24(daysAvailableIdx, :);
    nDaysOutVec = nDaysOutVec(daysAvailableIdx);
    simpleDaysOut = simpleDaysOut(daysAvailableIdx);
    
    intubation.simpleDate = yyyymmdd(intubation.ActivityDate);
    
    % Find intubation status x days out from thisDate
    daysOut = table(output24.SepsisID, simpleDaysOut);
    daysOutStatus = innerjoin(daysOut, intubation, ...
                              'LeftKeys', [1, 2], ...
                              'RightKeys', {'SepsisID', 'simpleDate'},...
                              'RightVariables', {'Intubated_YN_Numeric'});
    outputTable = output24;
    outputTable.outcomeDate = nDaysOutVec;
    outputTable.intubatedAtOutcome = daysOutStatus.Intubated_YN_Numeric;
end