function newData=integrateTemporalEhrFeatures(featureFile,temporalEHRFile, gapDuration, signalDuration, nWindows)
% DESCRIPTION: Extract and integrate temporal EHR features
%
% INPUTS
%     matfile    character array: full file name of the .mat file generated
%     by step_01_extract_features
%
% Language: MATLAB R2018b
% Author: Jonathan Gryak
% Modified by: Olivia Pifer Alge
% Date: January 12, 2020

addpath('../DOD/matlab/DataStructures/Interval Trees/');
addpath('../DOD/matlab/process_DOD_data/ehr_data/')
%% Start Timer
tic;

%% read saved features in
fn = matfile(featureFile);
savedFeatures = fn.signalsInfo;
temporalEHR = matfile(temporalEHRFile);

%% Set DSP
dsp.fullAnalysisWin = seconds(signalDuration);
dsp.winDuration = seconds(signalDuration / nWindows);
dsp.gap = seconds(gapDuration);
featureData.DSP = dsp;

%% Set additional information for featureData
featureData.numEvents = size(savedFeatures, 1); %sum(savedFeatures.qSofaTotal >= 2);
featureData.tFeatures = savedFeatures;
featureData.tFeatures.Properties.VariableNames(:, 13:16) = ...
    featureData.tFeatures.Properties.VariableNames(:, 13:16) + "_original";
featureData.tFeatureNames = cell2table(featureData.tFeatures.Properties.VariableNames, 'VariableNames', featureData.tFeatures.Properties.VariableNames);

%% convert each feature struct/name struct to table for editing, package for integration
labResults=temporalEHR.labresults;
standardVitals=temporalEHR.standardvitals;
uncommonVitals=temporalEHR.uncommonvitals;
urineOutput=temporalEHR.urineoutput;
medCVI=temporalEHR.medCVI;

%% process each positive patient event
%process lab results
[featureData.tFeatures]=integrate_labresults(labResults,featureData);
%process standard vitals
[featureData.tFeatures]=integrate_standardvitals(standardVitals,featureData);
%process uncommonvitals
[featureData.tFeatures]=integrate_uncommonvitals(uncommonVitals,featureData);
%process urineoutput
[featureData.tFeatures]=integrate_urineoutput(urineOutput,featureData);
%process medCVI
[featureData.tFeatures]=integrate_temporalmedications(medCVI,featureData);
%process extendedEHR
[featureData.tFeatures]=integrate_extendedEHR(medCVI,labResults,standardVitals,featureData);

%% convert to structs, save
[pathstr, name, ext] = fileparts(featureFile);
newFeatureFile=strcat(pathstr,filesep, name,'_temporalEHR',ext);
%make new matfile
copyfile(featureFile,newFeatureFile);
%save to new file
newsavedFeatures = matfile(newFeatureFile, 'Writable', true);
%% End timer
elapsedTime = toc;
fprintf('Elapsed Time in hours: %d \n', elapsedTime /60 / 60);
%%
disp('Script for integrating temporal EHR features has finished.');
newData.features = featureData.tFeatures;
newsavedFeatures.features = newData.features;
end