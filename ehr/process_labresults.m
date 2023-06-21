function labresults = process_labresults(filename,params)
% DESCRIPTION Function that process the labresults file
% 
% INPUTS
%   filename    character array: full file name of the CSV file
%               containing labresults. N.B. The CSV must be sorted
%               by Sepsis_ID,Sepsis_Enc_ID,CollectionDate, in that sequence 
%               in ascending order.
%
%   params      structure containing additional parameters:
%               savefile  - if set, save the results to filename savefile
%
% OUTPUTS
%   labresults  Map container for processed lab results: the keys
%               correspond to the values in featureNames; the values are a
%               a second map container whose keys are patient_id+enc_id and
%               whose values are IntervalTrees
%
% NOTES
%   Encoding for Lab Results
%       0 - Missing
%       1-4 in increasing severity
%
% Language: MATLAB R2017b
% Author: Jonathan Gryak
% Date: 20190131
%%
%map result codes to encoding functions
keys={'LACA2','LACA','ALACA'...%arterial lactate
    ,'LACTIC','LACV2','LACV'...%venous lactate
    ,'CREAT'...%creatinine
    ,'SOD'...%sodium
    ,'POT'...%potassium
    ,'GluA','GLUAA','GLUC','GLUC POC'...%glucose
    ,'GLUC-WB','GLUC_WB','GluV','GLUVV'...%glucose
    ,'HCT','HGB','PLT','WBC'...%complete blood count (CBC) values
    ,'INR'};%INR
values={@encodeLactateA,@encodeLactateA,@encodeLactateA...
    ,@encodeLactateV,@encodeLactateV,@encodeLactateV...
    ,@encodeCreatinine...
    ,@encodeSodium...
    ,@encodePotassium...
    ,@encodeGlucose,@encodeGlucose,@encodeGlucose,@encodeGlucose...
    ,@encodeGlucose,@encodeGlucose,@encodeGlucose,@encodeGlucose...
    ,@encodeHematocrit,@encodeHemoglobin,@encodePlatelets,@encodeWBC...
    ,@encodeINR};
encodingMap=containers.Map(keys,values);
%names of feature to extract
featureNames={'Lactate','Creatinine','Sodium','Potassium','Glucose','HCT','Hgb','PLT','WBC','INR'};
%end of time, for representing infinity
EOT=datenum(datetime("31-Dec-9999 12:00:00"));
%%
%read table
%lr=filename;
lr=readtable(filename);
[numRows,~]=size(lr);
%create result data structure, which maps feature names to a second
%container
labresults = containers.Map;
numFeatures=length(featureNames);
%map feature names to index
fIX=containers.Map(featureNames,1:numFeatures);
%create results map for each feature
for i=1:numFeatures
    %map patients to interval trees for each feature
    labresults(featureNames{i})=containers.Map;
end
interval=struct;
prevKey=NaN;
allIntervals=cell(1,numFeatures);
numIntervals=zeros(1,numFeatures);
%process each row
for row=1:numRows
    currSepsisID=lr{row,'SepsisID'};
    currSepsisEnc=lr{row,'EncID'};
    %create key
    currKey= string(currSepsisID)+currSepsisEnc;
    %check for new id/encounter pair
    if ~strcmp(prevKey,currKey)
        for i=1:numFeatures
            %check if not first interval
            if numIntervals(i)~=0
                %get interval tree for this result code and patient
                featureMap=labresults(featureNames{i});
                it=featureMap(prevKey);
                %add all intervals to the tree                
                for j=1:(numIntervals(i)-1)                    
                    interval.low=datenum(allIntervals{i}{j}{1});
                    interval.high=datenum(dateshift(allIntervals{i}{j+1}{1},'start','second','previous'));
                    it.Insert(interval,allIntervals{i}{j}{2});
                end
                %add final interval
                interval.low=datenum(allIntervals{i}{numIntervals(i)}{1});
                interval.high=EOT;
                it.Insert(interval,allIntervals{i}{numIntervals(i)}{2});
            end
        end
        %save key
        prevKey=currKey;
        %create new tree for the patient for each feature
        for i=1:numFeatures
            featureMap=labresults(featureNames{i});
            featureMap(currKey)=IntervalTree();
        end
        allIntervals=cell(1,numFeatures);
        numIntervals=zeros(1,numFeatures);
    end
    %process only supported result codes
    if isKey(encodingMap,lr{row,'RESULT_CODE'}{1})
        %get encoding function
        encodingFunction=encodingMap(lr{row,'RESULT_CODE'}{1});
        [featureName,encodedValue]=encodingFunction(row,lr);
        %get feature index
        index=fIX(featureName);
        %convert date to datetime
        newTime=datetime(lr{row,'OBSERVATION_DATE'},'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSS');
        %ignore duplicate times for the same feature
        if numIntervals(index) < 1 || allIntervals{index}{numIntervals(index)}{1}~=newTime 
            %increment numIntervals
            numIntervals(index)=numIntervals(index)+1;        
            %add new interval and encoded value to the cell array  
            allIntervals{index}{numIntervals(index)}={newTime,encodedValue};
        end
    end
end
%finalize last patient
for i=1:numFeatures
    %check if not first interval
    if numIntervals(i)~=0
        %get interval tree for this result code and patient
        featureMap=labresults(featureNames{i});
        it=featureMap(currKey);
        %add all intervals to the tree                
        for j=1:(numIntervals(i)-1)                    
            interval.low=datenum(allIntervals{i}{j}{1});
            interval.high=datenum(dateshift(allIntervals{i}{j+1}{1},'start','second','previous'));
            it.Insert(interval,allIntervals{i}{j}{2});
        end
        %add final interval
        interval.low=datenum(allIntervals{i}{numIntervals(i)}{1});
        interval.high=EOT;
        it.Insert(interval,allIntervals{i}{numIntervals(i)}{2});
    end
end
%save
if nargin==2 && isfield(params,'savefile')
    save(params.savefile,'labresults');
end
end
