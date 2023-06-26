function uncommonvitals = process_uncommonvitals(filename,params)
% DESCRIPTION Function that process the labresults file
% 
% INPUTS
%   filename    character array: full file name of the CSV file
%               containing labresults. N.B. The CSV must be sorted
%               by Sepsis_ID,Sepsis_Enc_ID,ObservationDate, in that sequence 
%               in asceding order.
%
%   params      structure containing additional parameters:
%               savefile  - if set, save the results to filename savefile
%
% OUTPUTS
%   uncommonvitals  data structure containing processed uncommonvitals
%
% NOTES
%
% Language: MATLAB R2018b
% OS: Windows 7
% Author: Jonathan Gryak
% Date: 20190123
%%
%Mike Mathis's Intubation Categorization
intubated={'SIMV','Intubated, unknown mode','Flowby','Assist Control','BiLevel'};
extubated={'Not intubated','Unknown / Missing','CPAP'};
%end of time, for representing infinity
EOT=datenum(datetime("31-Dec-9999 12:00:00"));
%%
idCol = 'SepsisID';
encCol = 'EncID';
dateCol = 'ObservationDate';
%read table
uv=readtable(filename);
uv=sortrows(uv, {idCol, encCol, dateCol});
[numRows,~]=size(uv);
%create result data structure,
uncommonvitals = containers.Map;
interval=struct;
numIntervals=0;

last_fio2=NaN;
last_peep=NaN;
last_ventcat=NaN;
last_ventstatus=NaN;

%process each row
for row=1:numRows
    currID=uv{row,idCol};
    currEnc=uv{row,encCol};
    %create key
    currKey= string(currID)+currEnc;
    %check for new id/encounter pair
    if ~isKey(uncommonvitals,currKey)
        %check if not first interval
        if numIntervals~=0
            %add all intervals to the tree
            it=uncommonvitals(prevKey);
            %numIntervals
            for j=1:(numIntervals-1)
                interval.low=datenum(allIntervals{j}{1});
                interval.high=datenum(dateshift(allIntervals{j+1}{1},'start','second','previous'));
                it.Insert(interval,allIntervals{j}(2:4));
            end
            %add final interval
            interval.low=datenum(allIntervals{numIntervals}{1});
            interval.high=EOT;
            it.Insert(interval,allIntervals{numIntervals}(2:4));
            
        end
        %save key
        prevKey=currKey;
        %create new tree
        uncommonvitals(currKey)=IntervalTree;
        allIntervals=cell(1);
        numIntervals=0;
    end
    curr_fio2=str2double(uv{row,'FiO2Set'});
    curr_peep=str2double(uv{row,'PEEPSet'});
    curr_ventcat=uv{row,'VentModeCategory'}{1};
    curr_ventstatus=0;
    drop_status=0;
    
    %drop record if all values are NULL
    if all(isnan([curr_fio2 curr_peep curr_ventcat]))
        drop_status=1;
    %handle each ventilation category differently when fio2 is null and peep is null
    elseif isnan(curr_fio2) && isnan(curr_peep)
        if ismember(curr_ventcat,['Assist Control' 'Intubated, unknown mode'])
            curr_fio2=last_fio2;
            curr_peep=last_peep;
            curr_ventstatus=last_ventstatus;
        elseif strcmp(curr_ventcat,'Not intubated')
            %test if VentMode indicates mechanical ventillation
            if strfind(uv{row,'VentMode'}{1},'Mechanical Ventilation')
                drop_status=1;
            else
                curr_fio2=21;
                curr_peep=0;
                curr_ventstatus=0;
            end
        elseif strcmp(curr_ventcat,'CPAP')
            %if last fio2 was unknown then impute status
            if isnan(last_fio2)
                curr_fio2=21;
                curr_peep=0;
                curr_ventstatus=0;
            %carry forward otherwise
            else
                curr_fio2=last_fio2;
                curr_peep=last_peep;
                curr_ventstatus=last_ventstatus;
            end                
        % for Flowby, SIMV, Unknown, or something else, drop
        else
            drop_status=1;
        end
    %bad records -  95 records out of 73354
    elseif isnan(curr_fio2) && ~isnan(curr_peep)
        drop_status=1;
    %if fio2 is OK but peep value is missing
    elseif ~isnan(curr_fio2) && isnan(curr_peep)
        %this often occurs when FiO2 is changed during intubated
        %ventilation
        if strcmp(curr_ventcat,"NULL")
            curr_peep=last_peep;
        %this often occurs when switching to extubated ventilation
        else
            curr_peep=0;
        end
    %now both fiO2 and peep are not null, check validity
    elseif curr_fio2 < 21 || curr_fio2 > 100 || curr_peep < 0 || curr_peep > 40
        drop_status=1;
    end
    %now fiO2 and peep have a valid range, but ventcat is null
    if strcmp(curr_ventcat,"NULL")
        %if f and p values are above normal, set last ventcat
        if curr_fio2 > 21 &&  curr_peep > 0
            curr_ventcat=last_ventcat;
        else
            curr_ventcat='Unknown';
        end
    end
    %continue the current interval if the current row was dropped or if the
    %values are all the same from the previous round
    if ~drop_status
        %categorize ventilation setting
        if ismember(curr_ventcat,intubated)
            curr_ventstatus=1;
        else
            %check for 'Mechnical Ventilation VentMode
            if strfind(uv{row,'VentMode'}{1},'Mechanical Ventilation')
                curr_ventstatus=1;
            else
               %extubated
             curr_ventstatus=0;
            end
        end
        %new values, terminate interval
        %if curr_fio2~=last_fio2 || curr_peep~=last_peep || ~strcmp(curr_ventcat,last_ventcat)
        if curr_fio2~=last_fio2 || curr_peep~=last_peep || curr_ventstatus~=last_ventstatus
            %increment numIntervals
            numIntervals=numIntervals+1;        
            %convert date to datetime
            newTime=datetime(uv{row,dateCol},'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSS');

            %add new interval and values to the cell array
            allIntervals{numIntervals}={newTime,curr_fio2,curr_peep,curr_ventstatus};
            %save values for next round
            last_fio2=curr_fio2;
            last_peep=curr_peep;
            last_ventcat=curr_ventcat;
            last_ventstatus=curr_ventstatus;
        end
    end    
end
%save
if nargin==2 && isfield(params,'savefile')
    save(params.savefile,'uncommonvitals');
end
end
