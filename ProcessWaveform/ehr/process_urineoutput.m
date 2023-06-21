function urineoutput = process_urineoutput(filename,params)
% DESCRIPTION Function that process the dailyintubation file
% 
% INPUTS
%   filename    character array: full file name of the CSV file
%               containing the urineoutput from the NursingFluidsDetailed 
%               view in RDW. N.B. The CSV must be sorted
%               by DoD_ID,DoD_Enc_ID, MedicationObservationDate, in that 
%               sequence and in ascending order.
%
%   params      structure containing additional parameters:
%               savefile  - if set, save the results to filename savefile
%
% OUTPUTS
%   urineoutput  data structure containing hourly urine output (in ML) for
%                each patient/encounter pair
%
%
% Language: MATLAB R2018b
% OS: Windows 10/OS X
% Author: Jonathan Gryak
% Date: 20190715
%%
%read table
uo=readtable(filename);
[numRows,~]=size(uo);
%create result data structure,
urineoutput = containers.Map;
interval=struct;
%use to track intervals that need to have hourly urine calculated
startTime=NaN;
%start of time, for representing -infinity
SOT=datenum(datetime("1-Jan-1970 00:00:00"));
%end of time, for representing infinity
EOT=datenum(datetime("31-Dec-9999 12:00:00"));
%state variables
%previous patient/encounter
prevKey=NaN;
%running total of urine output
runningTotal=0;
%process each row
for row=1:numRows
%for row=1:258
    currDoDID=uo{row,'SepsisID'};
    currDoDEnc=uo{row,'EncID'};
    %create key
    currKey= string(currDoDID)+currDoDEnc;
    %check for new id/encounter pair
    if ~isKey(urineoutput,currKey)
        %process last interval for previous key
        if isKey(urineoutput,prevKey)
            %if there were no valid values for this patient/enc, set to
            %zero for all time
            if it.Count==0
                interval.low=datenum(SOT);
                interval.high=datenum(EOT);
                it=urineoutput(prevKey);
                it.Insert(interval,0);       
            else
                if runningTotal > 0
                    %add <(startime,starttime+8 hours),runningtotal/8>
                    interval.low=datenum(startTime);
                    interval.high=datenum(dateshift(startTime,'end','seconds',28800));   
                    it=urineoutput(prevKey);
                    it.Insert(interval,runningTotal/8);                    
                    %add <(starttime+8hrs+1sec,infty),0>
                    interval.low=datenum(dateshift(startTime,'end','seconds',28801));
                    interval.high=datenum(EOT);
                    it=urineoutput(prevKey);
                    it.Insert(interval,0);
                else
                    %add <(starttime,infty),0>
                    interval.low=datenum(startTime);
                    interval.high=datenum(EOT);
                    it=urineoutput(prevKey);
                    it.Insert(interval,0);
                end                   
            end
        end
        %create new tree
        urineoutput(currKey)=IntervalTree;
        it=urineoutput(currKey);
        %save key
        prevKey=currKey;
        %reset runningtotal
        runningTotal=0;
    end
    %convert date to datetime
    currTime=datetime(uo{row,'ObservationDate'},'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSS');
    %convert value
    currUrine=uo{row,'Urine'};
    %skip if invalid currUrine
    if ~isnan(currUrine)
        %if first valid urine output
        if it.Count==0
            %add <(-\infty,currtime-1), 0> to IT
            interval.low=datenum(SOT);
            interval.high=datenum(dateshift(currTime,'start','seconds',-1));   
            it=urineoutput(currKey);
            it.Insert(interval,0);                    
            startTime=currTime;
            runningTotal=runningTotal+currUrine;
        else
            %MATLAB's diff does not work as expected: e.g., an exact difference 
            % of 8 hours yields the number 8.0001
            elapsedHours=hours(currTime - startTime);
            %if we haven't reached an hour's worth of time yet
            if elapsedHours < 1.0000
                runningTotal=runningTotal+currUrine;
            %between 1 and 8 hours, 8 hours max per Mathis
            elseif elapsedHours < 8.0002
                runningTotal=runningTotal+currUrine;
                %add <(starttime, currtime),runningTotal/elapsedHours
                interval.low=datenum(startTime);
                interval.high=datenum(dateshift(currTime,'start','seconds',-1));   
                it=urineoutput(currKey);
                it.Insert(interval,runningTotal/elapsedHours);                    
                runningTotal=0;
                startTime=currTime;
            %if greater than 8 hours, calculate average over that time, set
            %rest to 0
            else
                if runningTotal > 0
                    %add <(startime,starttime+8 hours),runningtotal/8>
                    interval.low=datenum(startTime);
                    interval.high=datenum(dateshift(startTime,'end','seconds',28800));   
                    it=urineoutput(currKey);
                    it.Insert(interval,runningTotal/8);                    
                    %add <(starttime+8hrs,1sec,currtime-1),0>
                    interval.low=datenum(dateshift(startTime,'end','seconds',28801));
                    interval.high=datenum(dateshift(currTime,'start','seconds',-1));   
                    it=urineoutput(currKey);
                    it.Insert(interval,0);
                    startTime=currTime;
                    runningTotal=currUrine;
                else
                    %add <(starttime,currtime-1),0>
                    interval.low=datenum(startTime);
                    interval.high=datenum(dateshift(currTime,'start','seconds',-1));   
                    it=urineoutput(currKey);
                    it.Insert(interval,0);
                    startTime=currTime;
                    runningTotal=currUrine;
                end
            end
        end
    end
end
%finalize last patient
%if there were no valid values for this patient/enc, set to
%zero for all time
if it.Count==0
    interval.low=datenum(SOT);
    interval.high=datenum(EOT);
    it=urineoutput(currKey);
    it.Insert(interval,0);       
else
    if runningTotal > 0
        %add <(startime,starttime+8 hours),runningtotal/8>
        interval.low=datenum(startTime);
        interval.high=datenum(dateshift(startTime,'end','seconds',28800));   
        it=urineoutput(currKey);
        it.Insert(interval,runningTotal/8);                    
        %add <(starttime+8hrs+1sec,infty),0>
        interval.low=datenum(dateshift(startTime,'end','seconds',28801));
        interval.high=datenum(EOT);
        it=urineoutput(currKey);
        it.Insert(interval,0);
    else
        %add <(starttime,infty),0>
        interval.low=datenum(startTime);
        interval.high=datenum(EOT);
        it=urineoutput(currKey);
        it.Insert(interval,0);
    end                   

end

%save
if nargin==2 && isfield(params,'savefile')
    save(params.savefile,'urineoutput');
end
end
