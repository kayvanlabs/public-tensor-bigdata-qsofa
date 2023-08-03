function stdvitals = process_standardvitals(filename,params)
% DESCRIPTION Function that process the labresults file
% 
% INPUTS
%   filename    character array: full file name of the CSV file
%               containing standardvitals. N.B. The CSV must be sorted
%               by Sepsis_ID,Sepsis_Enc_ID,ObservationDate, in that sequence 
%               in ascending order.
%
%   params      structure containing additional parameters:
%               savefile  - if set, save the results to filename savefile
%
% OUTPUTS
%   stdvitals  Map container for processed standard vitals: the keys
%               correspond to the values in featureNames; the values are a
%               a second map container whose keys are patient_id+enc_id and
%               whose values are IntervalTrees
%
% NOTES
% Currently, only temperature and SpO2 are implemented, though other vitals
% can be added in the future.
%
% Language: MATLAB R2018b
% Author: Jonathan Gryak, modified by Olivia Pifer Alge
% Modified: 20120113
%%
idCol = 'SepsisID';
encCol = 'EncID';
dateCol = 'ObservationDate';

newtimeIdx = 1;
eFeatureIdx = 2;
eFeatureTimeIdx = 3;

%names of feature to extract
featureNames={'Temperature','SpO2','HR','MAP','RespiratoryRate'};
%map columns to encoding functions
enc_values={@encodeTemp,@encodeSpO2,@encodeHR,@encodeMAP,@encodeRespiratoryRate};

encodingMap=containers.Map(featureNames,enc_values);
%end of time, for representing infinity
EOT=datenum(datetime("31-Dec-9999 12:00:00"));
%%
%read table
%lr=filename;
lr=readtable(filename);
lr=sortrows(lr, {idCol, encCol, dateCol});
[numRows,~]=size(lr);
%create result data structure, which maps feature names to a second
%container
stdvitals = containers.Map;  % NOTE: THIS IS PASS-BY-REFERENCE
numFeatures=length(featureNames);
%map feature names to index
fIX=containers.Map(featureNames,1:numFeatures);
%create results map for each feature
for i=1:numFeatures
    %map patients to interval trees for each feature
    stdvitals(featureNames{i})=containers.Map;
end
interval=struct;
%previous 
prevKey=NaN;
%state variables
[prevVal, prevTimes, allIntervals, numIntervals] = initializeEmpty(numFeatures);
%process each row
for row=1:numRows
    currID=lr{row,idCol};
    currEnc=lr{row,encCol};
    %create key
    currKey= string(currID)+currEnc;
    %check for new id/encounter pair
    if ~strcmp(prevKey,currKey)
        for i=1:numFeatures
            %check if not first interval
            if numIntervals(i)~=0
                %get interval tree for this vital sign and patient
                %disp([prevKey,featureNames{i},numIntervals(i)]);
                featureMap=stdvitals(featureNames{i});
                it=featureMap(prevKey);
                %add all intervals to the tree                
                for j=1:(numIntervals(i)-1)                    
                    interval.low=datenum(allIntervals{i}{j}{newtimeIdx});
                    interval.high=datenum(dateshift(allIntervals{i}{j+1}{newtimeIdx},'start','second','previous'));
                    it.Insert(interval,allIntervals{i}{j}([eFeatureIdx,eFeatureTimeIdx]));
                    %celldisp({allIntervals{i}{j}{newtimeIdx},dateshift(allIntervals{i}{j+1}{newtimeIdx},'start','second','previous'),allIntervals{i}{j}{eFeatureIdx}});
                end
                %add final interval
                interval.low=datenum(allIntervals{i}{numIntervals(i)}{newtimeIdx});
                interval.high=EOT;
                it.Insert(interval,allIntervals{i}{numIntervals(i)}([eFeatureIdx,eFeatureTimeIdx]));
                %celldisp({allIntervals{i}{numIntervals(i)}{newtimeIdx},EOT,allIntervals{i}{numIntervals(i)}{eFeatureIdx}});
            end
        end
        %save key
        prevKey=currKey;
        %create new tree for the patient for each feature
        for i=1:numFeatures
            featureMap=stdvitals(featureNames{i});
            featureMap(currKey)=IntervalTree();
        end
        [prevVal, prevTimes, allIntervals, numIntervals] = initializeEmpty(numFeatures);
    end
    %process supported vital signs
    for i=1:numFeatures
        %get encoding function
        encodingFunction=encodingMap(featureNames{i});
        [featureName,encodedValue,featureTime]=encodingFunction(row,lr,prevVal(i),prevTimes(i));
        %get feature index
        index=fIX(featureName);
        %convert date to datetime
        newTime=datetime(lr{row,dateCol},'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSS');
        %ignore duplicate times for the same feature
        if numIntervals(index) < 1 || allIntervals{index}{numIntervals(index)}{newtimeIdx}~=newTime
            %create new interval
            %increment numIntervals
            numIntervals(index)=numIntervals(index)+1;        
            %add new interval and encoded value to the cell array  
            allIntervals{index}{numIntervals(index)}={newTime,encodedValue,featureTime};
        end
        %update previous value for the feature
        prevVal(i)=encodedValue;
        prevTimes(i)=featureTime;
    end
end
%finalize last patient
for i=1:numFeatures
    %check if not first interval
    if numIntervals(i)~=0
        %get interval tree for this result code and patient
        featureMap=stdvitals(featureNames{i});
        it=featureMap(currKey);
        %add all intervals to the tree                
        for j=1:(numIntervals(i)-1)                    
            interval.low=datenum(allIntervals{i}{j}{newtimeIdx});
            interval.high=datenum(dateshift(allIntervals{i}{j+1}{newtimeIdx},'start','second','previous'));
            it.Insert(interval,allIntervals{i}{j}([eFeatureIdx,eFeatureTimeIdx]));
        end
        %add final interval
        interval.low=datenum(allIntervals{i}{numIntervals(i)}{newtimeIdx});
        interval.high=EOT;
        it.Insert(interval,allIntervals{i}{numIntervals(i)}([eFeatureIdx,eFeatureTimeIdx]));
    end
end
%save
if nargin==2 && isfield(params,'savefile')
    save(params.savefile,'stdvitals');
end
end

function [prevVal, prevValTimes, allIntervals, numIntervals] = initializeEmpty(numFeatures)
    %last seen value for each feature
    prevVal = repelem(NaN, numFeatures);
    prevValTimes = repelem(NaT, numFeatures);
    %stores intervals for processing at end
    allIntervals = cell(1, numFeatures);
    %number of intervals encountered per feature
    numIntervals = zeros(1, numFeatures);
    %process each row
end