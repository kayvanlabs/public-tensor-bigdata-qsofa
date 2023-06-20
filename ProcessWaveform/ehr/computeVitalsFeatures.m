function [vitalsFeatures, vitalsLocv] = computeVitalsFeatures(patientVitals)
% Compute features related to standard vitals
%
% Olivia Alge for BCIL, February 2020.
% Matlab 2019a, Windows 10
%
% DESCRIPTION
% Compute features from standard vitals and store in a table. Features
% computed include:
%
% INPUT
% patientVitals: table from ehr data vitals, only for one SepsisID
%
% OUTPUT
% vitalsFeatures: table of features taken from standard vitals table
    
    % use last observation carry forward to compute features
    locvVitals = fillmissing(patientVitals, 'previous');
    
    % Take mean of invasive and noninvasive systolic blood pressure
    meanSystolic = mean([patientVitals.BPSysInvasive, ...
                         patientVitals.BPSysNonInvasive], 2, 'omitnan');
    % Take mean of invasive and noninvasive diastolic blood pressure
    meanDiastolic = mean([patientVitals.BPDiaInvasive, ...
                          patientVitals.BPDiaNonInvasive], 2, 'omitnan');
    
    locvSystolic = fillmissing(meanSystolic, 'previous');
    locvDiastolic = fillmissing(meanDiastolic, 'previous');
    
    % from DOI: 10.1126/scitranslmed.aab3719
    shockIndex = locvVitals.HeartRate ./ locvSystolic;
    
    % count number of observations
    [nTempChecks, temperatureTable] = ...
                            computeNumChecks(patientVitals, 'Temperature');
                                      
    [nSpo2Checks spo2Table] = computeNumChecks(patientVitals, 'SpO2');
                               
    [nHRChecks, hrTable] = computeNumChecks(patientVitals, 'HeartRate');
                                    
    [nInvasiveBpChecks, invasiveTable] = ...
                         computeNumChecks(patientVitals, 'BPMeanInvasive');
                                     
    [nNonInvBpChecks, nonInvTable] = ...
                      computeNumChecks(patientVitals, 'BPMeanNonInvasive');
    
    % output
    SepsisID = patientVitals.SepsisID(1);
    vitalsFeatures = table(SepsisID, nHRChecks, ...
                           nTempChecks, nSpo2Checks, ...
                           nInvasiveBpChecks, nNonInvBpChecks);
    vitalsLocv = [locvVitals, ...
                  table(shockIndex, locvSystolic, locvDiastolic)];
end

function [nChecks, checkTable] = computeNumChecks(patientVitals, vitalName)
% Compute number of checks for given vital sign
    isObservation = ~isnan(patientVitals(:, vitalName).Variables);
    nChecks = sum(isObservation);
    checkDates = patientVitals.ObservationDate(isObservation);
    checkDiffs = [0; hours(diff(checkDates))];
    checkTable = table(checkDates, checkDiffs, 'VariableNames', ...
                       ["ObservationDate", ['HoursSinceLast', vitalName]]);
   % mean(checkDiffs);
   % checksPerDay = table(unique(patientVitals.ActivityDate), ...
   %                      groupcounts(patientVitals.ActivityDate), ...
   %                      'VariableNames', ["Day", "nChecks"]);
    
end