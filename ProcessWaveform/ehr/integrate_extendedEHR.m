function [updatedFeatures,updatedFeatureNames]=integrate_extendedEHR(medications,labResults,standardVitals,featureData)
%
% INPUTS
%     medications    a map containing temporal medication data created by
%                   process_medications
%     featureData   a structure containing the following fields from
%     step_01: 
%
% OUTPUTS
%   updatedFeatures     
%   updatedFeatureNames
%
% Language: MATLAB R2018b
% OS: Windows 10
% Author: Jonathan Gryak
% Date: 20200113

%% process each patient event
%determine number of additional time periods for each feature
%if gap <= 4 hours
if featureData.DSP.gap <=14400
    %number of look-back periods
    numPeriods=4;
    %length of the period to calculate the median in, in seconds
    lengthPeriod=14400;
%if gap = 8 or 12 hours
else  %if featureData.DSP.gap == 28800 || featureData.DSP.gap == 43200
    %number of look-back periods
    numPeriods=4;
    %length of the period to calculate the median in, in hours
    lengthPeriod=28800;
end
%concatenate addtional EHR maps
extendedFeatureMap=[medications;labResults;standardVitals];
featureNames=extendedFeatureMap.keys;
numFeatures=length(featureNames);

%create encodingMap, used to calculate median for encoded values
cviNames={'Dobutamine','Dopamine','Epinephrine',...
    'Isoproterenol','Milrinone','Norepinephrine','Vasopressin'};
labResultsNames={'Lactate','Creatinine','Sodium','Potassium','Glucose','HCT','Hgb','PLT','WBC','INR'};
%the stored value is the required length of the one-hot encoding, 2 in this
%case for all CVIs [0,0] - off; [0,1] - on; [1,0] elevated
%4 for lab results
encodingMap=[containers.Map(cviNames,repelem(1,length(cviNames)));...
    containers.Map(labResultsNames,repelem(1,length(labResultsNames)))];

%create cell arrays to hold additional feature values and names
extendedFeatures=cell(featureData.numEvents,numFeatures*numPeriods);
extendedFeatureNames=cell(featureData.numEvents,numFeatures*numPeriods);
for row=1:featureData.numEvents
    %create key from id/encounter
    currKey= string(featureData.tFeatures{row,'Sepsis_ID'})+string(str2double(featureData.tFeatures{row,'Sepsis_EncID'}{1}));
    %For R2018a and older: convert to char array
    %currKey=char(currKey);
    %calculate window intervals
    eventTime=featureData.tFeatures{row,'EventTime'};
    %calculate start time
    startTime=dateshift(eventTime,'start','second',-featureData.DSP.gap-ceil(featureData.DSP.fullAnalysisWin)-(numPeriods*lengthPeriod));
    %process each feature
    for findex=1:numFeatures
        %get feature name
        featureName=featureNames{findex};
        %create feature cell array
        featureArray=cell(1,numPeriods);
        %create featureNameArray
        featureNameArray=cell(numPeriods,1);
        %process each period
        for period=1:numPeriods
            %needed for parfor
            interval=struct;
            %calculate period time interval
            startInt=dateshift(startTime,'start','second',lengthPeriod*(period-1));
            interval.low=datenum(startInt);
            endInt=dateshift(startTime,'start','second',lengthPeriod*period);
            interval.high=datenum(endInt);
            %get feature container
            featureMap=extendedFeatureMap(featureName);
            %verify event has a value
            if isKey(featureMap,currKey)               
                it=featureMap(currKey);
                featnodes=it.SearchAll(interval);
                [~,numnodes]=size(featnodes);
                featvals=zeros(1,numnodes);
                %process one-hot encoded features
                if isKey(encodingMap,featureName)
                    %check if no values found
                    if numnodes==0 || isnan(featnodes{1}.key)
                        featval=zeros(1,encodingMap(featureName));
                    else
                        for node=1:numnodes
                            featvals(node)=onehot2dec(featnodes{node}.value);
                        end
                        featval=round(median(featvals));
                    end
                %process numerical features
                else
                    %check if no values found
                    if numnodes==0 || isnan(featnodes{1}.key)
                        featval=0;
                    else
                        for node=1:numnodes
                             featvals(node)=featnodes{node}.value;
                        end
                        featval=median(featvals);
                    end
                end
            else
                %encode missing value
                if isKey(encodingMap,featureName)
                    featval=zeros(1,encodingMap(featureName));
                else
                    featval=0;
                end
            end
            %store in featureArray
            featureArray{period}=featval;
            featureNameArray{period}=strcat(featureName,'Retro_Period_',string(period));
        end
        %add to new feature column
        extendedFeatures{row,findex}=featureArray;
        extendedFeatureNames{row,findex}=featureNameArray;
    end
end
%add feature/name to tables
newFeatureName=strcat(featureNames{1},'Retro');
updatedFeatures=addvars(featureData.tFeatures,extendedFeatures(:,1),'Before','EncodedOutcome','NewVariableNames',newFeatureName);
updatedFeatureNames=addvars(featureData.tFeatureNames,extendedFeatureNames(1,1),'Before','EncodedOutcome','NewVariableNames',newFeatureName);
for i=2:numFeatures
    newFeatureName=strcat(featureNames{i},'Retro');
    updatedFeatures=addvars(updatedFeatures,extendedFeatures(:,i),'Before','EncodedOutcome','NewVariableNames',newFeatureName);
    updatedFeatureNames=addvars(updatedFeatureNames,extendedFeatureNames(1,i),'Before','EncodedOutcome','NewVariableNames',newFeatureName);
end
end