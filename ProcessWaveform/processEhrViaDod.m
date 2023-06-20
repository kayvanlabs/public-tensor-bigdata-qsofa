% dod-ehr-integration.m
% DESCRIPTION: A script that processes EHR data, saving the data to two .mat files.
%
% INPUTS: EHR_path: char, where EHR data is stored
%
% Language: MATLAB R2020b
% Original Author: Jonathan Gryak
% Modified by: Olivia Pifer Alge
% May 2022

function processEhrViaDod(EHR_path)
    addpath('../DOD/matlab/process_DOD_data/ehr_data/');
    addpath('../DOD/matlab/DataStructures/Interval Trees/');
    %set path to EHR data
    curr_path=[EHR_path filesep];

    %load and process lab results (Sodium, Lactate, Cell Blood Counts, etc.)
    params.savefile=[curr_path 'labresults.mat'];
    lrFilename=[curr_path 'labs-all-with-gender.csv'];
    labresults = process_labresults(lrFilename,params);

    %load and process standard vital signs (currently temperature and SpO2)
    params.savefile=[curr_path 'standardvitals.mat'];
    svFilename=[curr_path 'nursingstandardvitalsigns-all.csv'];
    standardvitals = process_standardvitals(svFilename,params);

    %load and process uncommon vital signs (PEEP, FiO2, etc.)
    params.savefile=[curr_path 'uncommonvitals.mat'];
    uvFilename=[curr_path 'nursinguncommonvitals-all.csv'];
    uncommonvitals = process_uncommonvitals(uvFilename,params);

    %load and process medications administered during a patient's hospital stay
    params.savefile=[curr_path 'medications.mat'];
    medFilename=[curr_path 'medications-administered-all.csv'];
    medications = process_medications(medFilename,params);

    %load and process hourly urine output
    params.savefile=[curr_path 'urineoutput.mat'];
    uoFilename=[curr_path 'nursingfluidsdetailed-all.csv'];
    urineoutput = process_urineoutput(uoFilename,params);


    %stores EHR data whose values may change throughout a patient's stay 
    temporalEHRFile=[curr_path 'temporalEHR.mat'];
    %stores EHR data whose values do not change during a patient's stay 
    nontemporalEHRFile=[curr_path 'nontemporalEHR.mat'];

    %load saved results
    labResults=matfile([curr_path 'labresults.mat']);
    standardVitals=matfile([curr_path 'standardvitals.mat']);
    uncommonVitals=matfile([curr_path 'uncommonvitals.mat']);
    meds=matfile([curr_path 'medications.mat']);
    urine=matfile([curr_path 'urineoutput.mat']);

    %separate saved EHR data into temporal and non-temporal data, and save to disk
    standardvitals=standardVitals.stdvitals;
    uncommonvitals=uncommonVitals.uncommonvitals;
    labresults=labResults.labresults;
    medications=meds.medications;
    urineoutput=urine.urineoutput;
    medCVI=medications.CVI;
    mednonCVI=medications.nonCVI;
    mednonCVINames=medications.nonCVINames;
    save(temporalEHRFile,'uncommonvitals','labresults','medCVI','standardvitals','urineoutput');
    save(nontemporalEHRFile,'mednonCVI','mednonCVINames');
end