function ehrStruct = loadEhrData(configFile, groupChar)
% Load data from EHR file into a struct
%
% Olivia Alge for BCIL, April 2020.
% Matlab 2019a, Windows 10
%
% DESCRIPTION
% Loads EHR data from excel file and saves into the struct ehrStruct, with
% each element of the struct being one sheet of the excel file. Converts
% strings of dates to datetime format.
% 
% REQUIRES
% Excel file of EHR data is defined in the config file
%
% INPUT
% configFile: struct, stores location of EHR data, needs 1 of these fields:
%             'pediatric' OR 'troponin'
% groupChar: character vector, either 'pediatric' or 'troponin' to
%            determine which field in configFile to use
% 
% OUTPUT
% ehrStruct: a struct of tables, each table generated from one sheet of the
%            EHR file
    
    switch(groupChar)
        case('pediatric')
            ehrFileRead = configFile.pediatric.ehr;
        case('troponin')
            ehrFileRead = configFile.troponin.ehr;
        case('nonspecific')
            ehrFileRead = configFile.nonspecific.ehr;
    end

    % Read in sheets
    ehrStruct.patientInfo = loadPatientInfo(ehrFileRead);
    ehrStruct.encounters = loadEncounters(ehrFileRead);
    ehrStruct.demographics = loadDemographics(ehrFileRead);
    ehrStruct.labs = loadLabs(ehrFileRead);
    ehrStruct.comorbidities = condenseComorbidities(loadComorbidities(ehrFileRead));
    ehrStruct.fluidOutput = loadFluidOutput(ehrFileRead);
    ehrStruct.medicationsComp = loadMedicationsComp(ehrFileRead);
    ehrStruct.medicationsNursing = loadMedicationsNursing(ehrFileRead);
    ehrStruct.vitalsStandard = loadVitalsStandard(ehrFileRead);
    ehrStruct.vitalsUncommon = loadVitalsUncommon(ehrFileRead);
    ehrStruct.intubation = loadIntubation(ehrFileRead);
    
    if strcmp(groupChar, 'nonspecific')
        ehrStruct.diagnosesEverything = loadDiagnosesEverything(ehrFileRead);
        ehrStruct.nursingFluidInputs = loadNursingFluidInput(ehrFileRead);
        ehrStruct.anthropometrics = loadAnthropometrics(ehrFileRead);
        loadFlowsheets(ehrFileRead);
        ehrStruct.infusions = loadInfusions(ehrFileRead);
        
    end
    
    %uniqueIds = unique(ehrStruct.medicationsComp.SepsisID);
    %ehrStruct.medicationsCondensed = condenseMedicationsComp(uniqueIds, ...
    %                                            ehrStruct.medicationsComp);
end 

function patientInfo = loadPatientInfo(ehrFile)
% Reads the patient info sheet if it exists
    sheets = sheetnames(ehrFile);
    if ismember('PatientInfo', sheets)
        patientInfo = readtable(ehrFile, 'Sheet', 'PatientInfo');
    else
        patientInfo = [];
    end
end

function dateTimeOut = str2date(strIn)
% Converts a string/character vector of date/time in format 
% 'MM/dd/yyyy HH:mm' or 'yyyy-MM-dd HH:mm' to an EST datetime object

    if ~iscell(strIn)  % First, check if empty
        if ~sum(~isnan(strIn))  % if no dates at all
            dateTimeOut = NaT(length(strIn), 1);
        end
    else
        tz = 'America/New_York';
        expression = '\d{4}-\d{2}-\d{2}';
        
        if regexp(strIn{1}, expression)
            fmt = 'yyyy-MM-dd HH:mm:ss.SSSSSSS';
            dateTimeOut = datetime(strIn, ...
                                   'InputFormat', fmt, ...
                                   'TimeZone', tz);
        else
            dateTimeOut = datetime(strIn, ...
                                   'InputFormat', 'MM/dd/yyyy HH:mm', ...
                                   'TimeZone', tz);
        end
    end
    
end

function encounters = loadEncounters(ehrFile)
% read in encounters sheet from excel file
    encounters = readtable(ehrFile, 'Sheet', 'EncounterAll');
    encounters = changeTableStrsToDates(encounters);
end

function tableToFix = changeTableStrsToDates(tableToFix)
% Change string columns to datetime types

    % First, find columns with date information
    tableNames = tableToFix.Properties.VariableNames(...
                    contains(tableToFix.Properties.VariableNames, 'Date', 'IgnoreCase', true));
    
    for iName = tableNames
        disp(iName)
        tableToFix.(char(iName)) = str2date(tableToFix.(char(iName)));
    end
    
end

function demographics = loadDemographics(ehrFile)
% read in demographics sheet from excel file
    demographics = readtable(ehrFile, 'Sheet', 'DemographicInfo');
    demographics = changeTableStrsToDates(demographics);
end

function labs = loadLabs(ehrFile)
% read in labs sheet from excel file
    labs = readtable(ehrFile, 'Sheet', 'LabResults');
    labs = changeTableStrsToDates(labs);
end

function comorbidities = loadComorbidities(ehrFile)
% read in comorbidities sheet from excel file
    comorbidities = readtable(ehrFile, 'Sheet', ...
                              'ComorbiditiesE...rComprehensive');
    comorbidities = changeTableStrsToDates(comorbidities);
end

function fluidInput = loadNursingFluidInput(ehrFile)
% read in fluid input sheet from excel file
    fluidInput = readtable(ehrFile, 'Sheet', 'NursingHourlyFluidInputTotals');
    fluidInput = changeTableStrsToDates(fluidInput);
end

function fluidOutput = loadFluidOutput(ehrFile)
% read in fluid output sheet from excel file
    fluidOutput = readtable(ehrFile, 'Sheet', ...
                            'NursingHourlyFluidOutputTotals');
    fluidOutput = changeTableStrsToDates(fluidOutput);
end

function medicationsComp = loadMedicationsComp(ehrFile)
% read in comprehensive medications sheet from excel file
    medicationsComp = readtable(ehrFile, 'Sheet', ...
                                'MedicationAdmi...sComprehensive');
    medicationsComp = changeTableStrsToDates(medicationsComp);
    medicationsComp.OrderStart = str2date(medicationsComp.OrderStart);
    medicationsComp.OrderStop = str2date(medicationsComp.OrderStop);
    medicationsComp.DoseStartTime = str2date(medicationsComp.DoseStartTime);
    medicationsComp.DoseEndTime = str2date(medicationsComp.DoseEndTime);
end

function medsNursing = loadMedicationsNursing(ehrFile)
% read in nursing medications sheet from excel file
    medsNursing = readtable(ehrFile, 'Sheet', ...
                            'NursingMedicat...usionsDetailed');
    medsNursing = changeTableStrsToDates(medsNursing);
end

function vitalsStd = loadVitalsStandard(ehrFile)
% read in standard vital signs sheet from excel file
    vitalsStd = readtable(ehrFile, 'Sheet', 'NursingStandardVitalSigns');
    vitalsStd = changeTableStrsToDates(vitalsStd);
end

function vitalsUnc = loadVitalsUncommon(ehrFile)
% read in uncommon vital signs sheet from excel file
    vitalsUnc = readtable(ehrFile, 'Sheet', 'NursingUncommonVitalSigns');
    vitalsUnc = changeTableStrsToDates(vitalsUnc);
end

function diagnoses = loadDiagnosesEverything(ehrFile)
    diagnoses = readtable(ehrFile, 'Sheet', 'DiagnosesEverything');    
end

function anthropometrics = loadAnthropometrics(ehrFile)
    anthropometrics = readtable(ehrFile, 'Sheet', 'EncounterAnthropometricsBMI');
end

function flowsheets = loadFlowsheets(ehrFile)
% Read in all flowsheets data
    sheets = sheetnames(ehrFile);
    flowsheetNames = sheets(contains(sheets, 'FlowsheetsDetailed'));
    flowsheets = [];
    for i = 1:length(flowsheetNames)
        iFlowsheet = readtable(ehrFile, 'Sheet', flowsheetNames(i));
        iFlowsheet = changeTableStrsToDates(iFlowsheet);
        try
            if all(isnan(iFlowsheet.Unit))
                iFlowsheet.Unit = repmat({''}, [length(iFlowsheet.Unit), 1]);
            end
        catch  % must be string/char if non NaN
        end
        flowsheets = [flowsheets; iFlowsheet];
    end
    saveName = fullfile('Z:/Projects/Tensor_Sepsis/Data/Processed/Non-Specific/EHR/flowsheet.mat');
    save(saveName, 'flowsheets', '-v7.3');
end

function intubation = loadIntubation(ehrFile)
% read in intubation data sheet form excel file
    sheets = sheetnames(ehrFile);
    if ismember('DailyIntubation', sheets)
        opts = detectImportOptions(ehrFile, 'Sheet', 'DailyIntubation');
        opts.VariableTypes = {'double', 'double', 'char', 'char', 'double', 'char'};
        intubation = readtable(ehrFile, opts);
        intubation = changeTableStrsToDates(intubation);
    else
        intubation = [];
    end
end

function infusions = loadInfusions(ehrFile)
    infusions = readtable(ehrFile, 'Sheet', 'NursingMedicat...usionsDetailed');
    infusions = changeTableStrsToDates(infusions);
end