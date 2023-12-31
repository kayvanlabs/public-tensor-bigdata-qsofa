% dod-ehr-integration.m
% DESCRIPTION: A script that processes EHR data, saving the data to two .mat files.
%
% INPUTS: EHR_path: char, where EHR data is stored
%
% Language: MATLAB R2020b
% Original Author: Jonathan Gryak
% Modified by: Olivia Pifer Alge
% May 2022

function processEhr(EHR_path)
    addpath('Interval Trees/');
    %set path to EHR data
    curr_path=[EHR_path filesep];
    save_path='./';

    %load and process lab results (Sodium, Lactate, Cell Blood Counts, etc.)
    params.savefile=[save_path 'labresults.mat'];
    lrFilename=[curr_path 'labs-all-with-gender.csv'];
    labresults = process_labresults(lrFilename,params);

    %load and process standard vital signs (currently temperature and SpO2)
    params.savefile=[save_path 'standardvitals.mat'];
    svFilename=[curr_path 'nursingstandardvitalsigns-all.csv'];
    standardvitals = process_standardvitals(svFilename,params);

    %load and process uncommon vital signs (PEEP, FiO2, etc.)
    params.savefile=[save_path 'uncommonvitals.mat'];
    uvFilename=[curr_path 'nursinguncommonvitals-all.csv'];
    uncommonvitals = process_uncommonvitals(uvFilename,params);

    %load and process medications administered during a patient's hospital stay
    params.savefile=[save_path 'medications.mat'];
    medFilename=[curr_path 'medications-administered-all.csv'];
    medications = process_medications(medFilename,params);

    %load and process hourly urine output
    params.savefile=[save_path 'urineoutput.mat'];
    uoFilename=[curr_path 'nursingfluidsdetailed-all.csv'];
    urineoutput = process_urineoutput(uoFilename,params);


    %stores EHR data whose values may change throughout a patient's stay 
    temporalEHRFile=[save_path 'temporalEHR.mat'];
    %stores EHR data whose values do not change during a patient's stay 
    nontemporalEHRFile=[save_path 'nontemporalEHR.mat'];

    %load saved results
    labResults=matfile([save_path 'labresults.mat']);
    standardVitals=matfile([save_path 'standardvitals.mat']);
    uncommonVitals=matfile([save_path 'uncommonvitals.mat']);
    meds=matfile([save_path 'medications.mat']);
    urine=matfile([save_path 'urineoutput.mat']);

    %separate saved EHR data into temporal and non-temporal data, and save to disk
    standardvitals=standardVitals.stdvitals;
    uncommonvitals=uncommonVitals.uncommonvitals;
    labresults=labResults.labresults;
    medications=meds.medications;
    urineoutput=urine.urineoutput;
    medCVI=medications.CVI;
    mednonCVI=medications.nonCVI;
    mednonCVINames=medications.nonCVINames;
    save(temporalEHRFile,'uncommonvitals','labresults','medCVI','standardvitals','urineoutput', '-v7.3');
    save(nontemporalEHRFile,'mednonCVI','mednonCVINames');
end