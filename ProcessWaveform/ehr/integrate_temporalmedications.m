function [updatedFeatures,updatedFeatureNames]=integrate_temporalmedications(medications,featureData)
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
% OS: Windows 7
% Author: Jonathan Gryak
% Date: 20190205

%% process each patient event
featureNames=medications.keys;
numFeatures=length(featureNames);
MedFeatures=cell(featureData.numEvents,numFeatures);
MedFeatureNames=cell(featureData.numEvents,numFeatures);
%calculate number of windows
numWindows = round(featureData.DSP.fullAnalysisWin/featureData.DSP.winDuration);
for row=1:featureData.numEvents
    %create key from id/encounter
    currKey= string(featureData.tFeatures{row,'Sepsis_ID'})+string(str2double(featureData.tFeatures{row,'Sepsis_EncID'}{1}));
    %calculate window intervals
    eventTime=featureData.tFeatures{row,'EventTime'};
    %process each feature
    for findex=1:numFeatures
        %get feature name
        featureName=featureNames{findex};
        %create feature cell array
        featureArray=cell(1,numWindows);
        %create featureNameArray
        featureNameArray=cell(numWindows,1);
        %calculate start time
        startTime=dateshift(eventTime,'start','second',-featureData.DSP.gap-ceil(featureData.DSP.fullAnalysisWin));
        %process each window
        for win=1:numWindows
            %needed for parfor
            interval=struct;
            %calculate window time interval
            startInt=dateshift(startTime,'start','second',floor(featureData.DSP.winDuration*(win-1)));
            interval.low=datenum(startInt);
            endInt=dateshift(startTime,'start','second',floor(featureData.DSP.winDuration*win));
            interval.high=datenum(endInt);
            %get feature container
            featureMap=medications(featureName);
            %verify event has a value
            if isKey(featureMap,currKey)               
                it=featureMap(currKey);
                featval=it.Search(interval).value;
                %check for missing value and encode
                if isempty(featval)
                    featval=0;
                end
            else
                %encode missing value
                featval=0;
            end
            %store in featureArray
            featureArray{win}=featval;
            featureNameArray{win}=strcat(featureName,'_subwin_',string(win));
        end
        %add to new feature column
        MedFeatures{row,findex}=featureArray;
        MedFeatureNames{row,findex}=featureNameArray;
    end
end
%add feature/name to tables
updatedFeatures=addvars(featureData.tFeatures,MedFeatures(:,1),'Before','EncodedOutcome','NewVariableNames',featureNames{1});
updatedFeatureNames=addvars(featureData.tFeatureNames,MedFeatureNames(1,1),'Before','EncodedOutcome','NewVariableNames',featureNames{1});
for i=2:numFeatures
    updatedFeatures=addvars(updatedFeatures,MedFeatures(:,i),'Before','EncodedOutcome','NewVariableNames',featureNames{i});
    updatedFeatureNames=addvars(updatedFeatureNames,MedFeatureNames(1,i),'Before','EncodedOutcome','NewVariableNames',featureNames{i});
end
end