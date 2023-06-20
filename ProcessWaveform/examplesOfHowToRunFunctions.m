%% Using the config file
% If using Great Lakes, you'll want to use the relative config file, 
% which, assumes the current working directory is ProcessWaveform/
configFile = jsondecode(fileread('../configRelative.json'));

% Else, if using Turbo stored as the 'Z:/' drive, use the general config file
configFile = jsondecode(fileread('../config.json'));

%% Loading waveform times

% For pediatric data
waveformTimes = loadWaveformTimes(configFile.pediatric.waveformTimes, 'pediatric');

% For troponin data
waveformTimes = loadWaveformTimes(configFile.troponin.waveformTimes, 'troponin');

%% Loading EHR data for first time

% For pediatric data
ehrStruct = loadEhrData(configFile, 'pediatric');

% For troponin data
ehrStruct = loadEhrData(configFile, 'troponin');

% Loading EHR data from file

ehrFile = configFile.troponin.ehrStruct;
ehrStruct = matfile(ehrFile);
patientInfo = ehrStruct.ehrStruct.patientInfo;
meds = ehrStruct.ehrStruct.medicationsComp;