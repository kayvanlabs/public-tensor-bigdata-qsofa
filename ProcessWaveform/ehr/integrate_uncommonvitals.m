function [updatedFeatures,updatedFeatureNames]=integrate_uncommonvitals(uncommonVitals,featureData)
%
% INPUTS
%     labresults    a structure containing data created by
%                   process_uncommonvitals
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
% Date: January 25, 2019

%% process each patient event
numFeatures=3;
UncommonVitals=cell(featureData.numEvents,numFeatures);
UncommonVitalsNames=cell(featureData.numEvents,numFeatures);
%calculate number of windows
numWindows = round(featureData.DSP.fullAnalysisWin/featureData.DSP.winDuration);
for row=1:featureData.numEvents
    %create key from id/encounter
    currKey= string(featureData.tFeatures{row,'Sepsis_ID'})+string(str2double(featureData.tFeatures{row,'Sepsis_EncID'}{1}));
    %disp(currKey);
    %calculate window intervals
    eventTime=featureData.tFeatures{row,'EventTime'};
    %calculate start time
    startTime=dateshift(eventTime,'start','second',-featureData.DSP.gap-ceil(featureData.DSP.fullAnalysisWin));
    %create feature cell array
    featureArray=cell(numFeatures,numWindows);
    %create featureNameArray
    featureNameArray=cell(numWindows,numFeatures);
    %featureNameArray=repmat({'FiO2' 'PEEP' 'Intubated'},numWindows,1);
    %process each window
    for win=1:numWindows
        %needed for parfor
        interval=struct;
        %calculate window time interval
        startInt=dateshift(startTime,'start','second',floor(featureData.DSP.winDuration*(win-1)));
        interval.low=datenum(startInt);
        endInt=dateshift(startTime,'start','second',floor(featureData.DSP.winDuration*win));
        interval.high=datenum(endInt);
        %process each feature
        %get interval tree
        %verify event has a value
        if isKey(uncommonVitals,currKey)
            it=uncommonVitals(currKey);
            %get uncommonvitals
            ucvitals=it.Search(interval).value;
            %check for missing value and set if necessary
            if isempty(ucvitals)
                ucvitals={21, 0, 0};
            end
        else
            %set missing value
            ucvitals={21, 0, 0};
        end
        %store in featureArray
        for i=1:numFeatures
            featureArray{i,win}=ucvitals{i};
            winSuffix=strcat('_subwin_',string(win));
            featureNameArray(win,:)={strcat('FiO2',winSuffix) strcat('PEEP',winSuffix) strcat('Intubated',winSuffix)};
        end
    end
    %add to new feature column
    %celldisp(featureArray);
    for i=1:numFeatures
        UncommonVitals{row,i}=featureArray(i,:);
        UncommonVitalsNames{row,i}=featureNameArray(:,i);
    end
end
%add feature/name to tables
updatedFeatures=addvars(featureData.tFeatures,UncommonVitals(:,1),UncommonVitals(:,2),UncommonVitals(:,3),'Before','EncodedOutcome','NewVariableNames',{'FiO2','PEEP','Intubated'});
updatedFeatureNames=addvars(featureData.tFeatureNames,UncommonVitalsNames(1,1),UncommonVitalsNames(1,2),UncommonVitalsNames(1,3),'Before','EncodedOutcome','NewVariableNames',{'FiO2','PEEP','Intubated'});
end