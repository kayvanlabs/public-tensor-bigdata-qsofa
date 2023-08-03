function [outputTime] = convertTime(inputTime)
% Convert the unix timestamp (epoch) or java Date.parse into
% MATLAB or normal date string/number. 
% Input:
%   inputTime: str, UNIX timestamp 
% Output:
%   outputTime: str, date/time for EST
    
    if isnumeric(inputTime)
        outputTime = datetime(inputTime, 'ConvertFrom', 'posixtime', ...
                         'TimeZone', 'America/New_York');
    else
        %input_char =  char(inputTime);
        %d = datetime(input_char(:, 1:19), 'TimeZone', 'America/New_York');
        outputTime = posixtime(inputTime);
    end
end