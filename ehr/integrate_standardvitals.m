function [updatedFeatures,updatedFeatureNames]=integrate_standardvitals(standardVitals,featureData)
%
% INPUTS
%     standardVitals    a map containing data created by
%                   process_labresults
%     featureData   a structure containing the following fields from
%     step_01: 
%
% OUTPUTS
%   updatedFeatures     
%   updatedFeatureNames
%
% Language: MATLAB R2019a
% OS: Windows 10
% Author: Jonathan Gryak
% Date: 20200324

%%
% Set columns
cols.id = 'SepsisID';
cols.enc = 'EncID';
cols.outcome = 'Label';
cols.signalStart = 'predictionSignalStart';
cols.signalEnd = 'predictionSignalEnd';
%% process each patient event
featureNames=standardVitals.keys;
numFeatures=length(featureNames);
SVFeatures=cell(featureData.numEvents,numFeatures);
SVFeatureTimes=cell(featureData.numEvents,numFeatures);
SVFeatureNames=cell(featureData.numEvents,numFeatures);
%calculate number of windows
numWindows = round(featureData.DSP.fullAnalysisWin/featureData.DSP.winDuration);
for row=1:featureData.numEvents
    %create key from id/encounter
    currKey= string(featureData.tFeatures{row,cols.id})+string(str2double(featureData.tFeatures{row,cols.enc}{1}));
    %process each feature
    for findex=1:numFeatures
        %get feature name
        featureName=featureNames{findex};
        %create feature cell array
        featureArray=cell(1,numWindows);
        %create timing array
        timingArray=cell(1,numWindows);
        %create featureNameArray
        featureNameArray=cell(numWindows,1);
        %calculate start time
        startTime=featureData.tFeatures{row,cols.signalStart};
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
            featureMap=standardVitals(featureName);
            %verify event has a value
            if isKey(featureMap,currKey)               
                it=featureMap(currKey);
                winval=it.Search(interval);
                
                %check for missing value
                if isempty(winval.value)
                    featval=nan;
                    featTime=nan;
                else
                    featval=winval.value{1};
                    fTime=winval.value{2};
                    fTime.TimeZone = startInt.TimeZone;
                    featTime=seconds(startInt - fTime); 
                end
            else
                %set missing value
                featval=nan;
                featTime=nan;
            end
            %store in featureArray
            featureArray{win}=featval;
            timingArray{win}=featTime;
            featureNameArray{win}=strcat(featureName,'_subwin_',string(win));
        end
        %add to new feature column
        SVFeatures{row,findex}=featureArray;
        SVFeatureTimes{row,findex}=timingArray;
        SVFeatureNames{row,findex}=featureNameArray;
    end
end
%add feature/name to tables
updatedFeatures=addvars(featureData.tFeatures,SVFeatures(:,1),'Before',cols.outcome,'NewVariableNames',featureNames{1});
updatedFeatures=addvars(updatedFeatures,SVFeatureTimes(:,1),'Before',cols.outcome,'NewVariableNames',strcat(featureNames{1},'_secondsBeforeWindow'));
updatedFeatureNames=addvars(featureData.tFeatureNames,SVFeatureNames(1,1),'Before',cols.outcome,'NewVariableNames',featureNames{1});
for i=2:numFeatures
    updatedFeatures=addvars(updatedFeatures,SVFeatures(:,i),'Before',cols.outcome,'NewVariableNames',featureNames{i});
    updatedFeatures=addvars(updatedFeatures,SVFeatureTimes(:,i),'Before',cols.outcome,'NewVariableNames',strcat(featureNames{i},'_secondsBeforeWindow'));
    updatedFeatureNames=addvars(updatedFeatureNames,SVFeatureNames(1,i),'Before',cols.outcome,'NewVariableNames',featureNames{i});
end
end