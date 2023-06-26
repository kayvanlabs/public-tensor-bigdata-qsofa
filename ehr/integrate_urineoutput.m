function [updatedFeatures,updatedFeatureNames]=integrate_urineoutput(urineoutput,featureData)
%
% INPUTS
%     urineoutput   a structure containing data created by
%                   process_urineoutput
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

%%
% Set columns
cols.id = 'SepsisID';
cols.enc = 'EncID';
cols.outcome = 'Label';
cols.signalStart = 'predictionSignalStart';
cols.signalEnd = 'predictionSignalEnd';
%% process each patient event
UrineOutputs=cell(featureData.numEvents,1);
UrineOutputsNames=cell(featureData.numEvents,1);
%calculate number of windows
numWindows = round(featureData.DSP.fullAnalysisWin/featureData.DSP.winDuration);
for row=1:featureData.numEvents
    %create key from id/encounter
    currKey= string(featureData.tFeatures{row,cols.id})+string(str2double(featureData.tFeatures{row,cols.enc}{1}));
    %calculate start time
    startTime=featureData.tFeatures{row,cols.signalStart};
    %create feature cell array
    featureArray=cell(1,numWindows);
    %create featureNameArray
    featureNameArray=cell(numWindows,1);
    %process each window
    for win=1:numWindows
        %needed for parfor
        interval=struct;
        %calculate window time interval
        startInt=dateshift(startTime,'start','second',floor(featureData.DSP.winDuration*(win-1)));
        interval.low=datenum(startInt);
        endInt=dateshift(startTime,'start','second',floor(featureData.DSP.winDuration*win));
        interval.high=datenum(endInt);
        %verify event has a value
        if isKey(urineoutput,currKey)
            it=urineoutput(currKey);
            %get urineoutput
            uo=it.Search(interval).value;
        else
            %set value for missing patient
            uo=nan;
        end
        %store in featureArray
        featureArray{1,win}=uo;
        winSuffix=strcat('_subwin_',string(win));
        featureNameArray(win,:)={strcat('UrineOutput',winSuffix)};
    end
    %add to new feature column
    UrineOutputs{row,1}=featureArray(1,:);
    UrineOutputsNames{row,1}=featureNameArray(:,1);
end

%add feature/name to tables
updatedFeatures=addvars(featureData.tFeatures,UrineOutputs(:,1),'Before',cols.outcome,'NewVariableNames',{'UrineOutput'});
updatedFeatureNames=addvars(featureData.tFeatureNames,UrineOutputsNames(1,1),'Before',cols.outcome,'NewVariableNames',{'UrineOutput'});
end