function [bestValidationResults, bestModels, testResults, allResults] = callBasicMITrainingWithMI(baseFolder, useRank, useEhr, sName, expName, modelType)
    baseFile = 'feature_vectors_';
    % expName = 'prediction_360_minutes_signal_10_minutes_ECG_Art';
    fname = 'feature_vectors';
    useMetric = 'F1_score';
    bestValidationResults = [];
    bestModels = [];
    testResults = [];
    allResults = [];
    addpath('../../BCIL-Shared/mRMR/BCILpackage/');
    
    miValuesEcg = [];
    miValuesArt = [];
    useMi = false;
    nMiColumns = 20;
    
    % For selecting waveform types
    useArt = true;
    useEcg = true;
    
    % Set up iterations
    seedValues = 0:99;
    if isempty(getenv('SLURM_JOB_ID'))
        trial = seedValues;
        disp('Using seedValues 0-99');
    else
        trial = seedValues(str2double(getenv('SLURM_ARRAY_TASK_ID')));
        disp(['Using SLRUM TASK ID ', getenv('SLURM_ARRAY_TASK_ID')]);
    end

    for i = trial
        % Load in feature tables
        iName = strcat(baseFile, num2str(i), '.mat');
        
        % ECG features
        tempName = strcat('ECG_', expName, '_TS');
        ecgFeatures = load(fullfile(baseFolder, tempName, iName));
        tableOfEcgFeatures = ecgFeatures.(fname);
        rankRows = tableOfEcgFeatures.Rank == useRank;
        tableOfEcgFeatures = tableOfEcgFeatures(rankRows, :);
        
        % Art features
        tempName = strcat('Art_', expName, '_ABP');
        artFeatures = load(fullfile(baseFolder, tempName, iName));
        tableOfArtFeatures = artFeatures.(fname);
        rankRows = tableOfArtFeatures.Rank == useRank;
        tableOfArtFeatures = tableOfArtFeatures(rankRows, :);
        
        % Create training data
        tableOfFeatures = appendWaveformDataTypes(tableOfEcgFeatures, ...
                                                  tableOfArtFeatures, ...
                                                  ecgFeatures, artFeatures, ...
                                                  useEhr, useArt, useEcg);
        if useMi
            % Calc MI values
            miValuesEcg = [miValuesEcg; getMutualInfoQuick(tableOfEcgFeatures)];
            miValuesArt = [miValuesArt; getMutualInfoQuick(tableOfArtFeatures)];
            tableOfFeatures = applyMi(tableOfFeatures, nMiColumns);
        end
        
        % Train models
        switch modelType
            case 'rf'
                [iBestResults, iBestModel, iAllReslts] = trainRfWithGrid(tableOfFeatures, ...
                                                                         useRank, ...
                                                                         useMetric, ...
                                                                         i);
            case 'lucck'
                [iBestResults, iBestModel, iAllReslts] = trainLucckWithGrid(tableOfFeatures, ...
                                                                            useRank, ...
                                                                            useMetric, ...
                                                                            i);
            case 'svm'
                [iBestResults, iBestModel, iAllReslts] = trainSvmWithGrid(tableOfFeatures, ...
                                                                          useRank, ...
                                                                          useMetric, ...
                                                                          i);
            otherwise
                error(strcat(modelType, " is not a supported model type", ...
                             " or is not a char vector."));
        end
        
        bestValidationResults = [bestValidationResults; iBestResults];
        bestModels = [bestModels; iBestModel];
        allResults = [allResults; iAllReslts];
        testResults = [testResults; calcVotingResults(iBestModel, ...
                                                      tableOfFeatures, ...
                                                      useRank)];
    end
    
    save(strcat(sName, num2str(i), '.mat'), ...
         'bestValidationResults', 'bestModels', 'testResults', 'allResults', ...
         'miValuesEcg', 'miValuesArt', '-v7.3');
end

function miValues = getMutualInfoQuick(tableIn)
% Calculate mutual information score for 3 folds of training data
    miValues = [];
    for k = 1:3
        kTable = tableIn{k, 'Training_X'}{1};
        kLabel = tableIn{k, 'Training_Y'}{1};
        nVars = size(kTable, 2);
        for j = 1:nVars
            miScr(j) = mutualinfo(kTable(:, j), kLabel);
        end
        % Sort scores from high to low
        [miScr, scrIdx] = sort(miScr, 'descend');
        kValues.MI_Score = miScr;
        kValues.ColumnIndex = scrIdx;
        kValues.Fold = repelem(k, nVars);
        miValues = [miValues; kValues];
    end
end

function allData = appendWaveformDataTypes(ecgTable, artTable, ecgStruct, artStruct, useEhr, useArt, useEcg)
% Append features from two different signal types together
    
    % First, make sure indexing is the same
    sameTest = isequal(ecgStruct.testIds, artStruct.testIds);
    sameTrain = isequal(ecgStruct.trainIds, artStruct.trainIds);
    sameIdx = isequal(ecgStruct.training_idxs, artStruct.training_idxs);
    if ~(sameTest && sameTrain && sameIdx)
        error('Training / Validation / Test do not match up')
    end
    
    % Append information
    allData = ecgTable;
    allData.Training_X = appendForFolds(ecgTable, artTable, useEhr, useArt, useEcg, 'Training_X');
    allData.Validation_X = appendForFolds(ecgTable, artTable, useEhr, useArt, useEcg, 'Validation_X');
    allData.Test_X = appendForFolds(ecgTable, artTable, useEhr, useArt, useEcg, 'Test_X');
end

function columnOut = appendForFolds(ecgTab, artTab, ehrBool, artBool, ecgBool, col)
    columnOut = ecgTab.(col);
    % Remove EHR features from one of the tables
    nEhr = 140;  % There are 140 EHR features
    nColsEcg = size(columnOut{1}, 2);
    nColsArt = size(artTab{1, col}{1}, 2);
    if nColsEcg <= nEhr  % No EHR included
        waveIdxEcg = 1:nColsEcg;
        waveIdxArt = 1:nColsArt;
        ehrIdx = [];
    else
        waveIdxEcg = 1:(nColsEcg - nEhr);
        waveIdxArt = 1:(nColsArt - nEhr);
        ehrIdx = (waveIdxEcg(end) + 1):nColsEcg;  % EHR is always appended to the end
    end
    for i = 1:3
        % Select each type of feature
        ecgFeats = ecgTab{i, col}{1};
        ehrFeats = ecgFeats(:, ehrIdx);
        ecgFeats = ecgFeats(:, waveIdxEcg);
        
        artFeats = artTab{i, col}{1};
        artFeats = artFeats(:, waveIdxArt);
        if ecgBool && artBool
            if ehrBool
                columnOut{i} = [ecgFeats, artFeats, ehrFeats];
            else
                columnOut{i} = [ecgFeats, artFeats];
            end
        elseif ecgBool
            if ehrBool
                columnOut{i} = [ecgFeats, ehrFeats];
            else
                columnOut{i} = [ecgFeats];
            end
        elseif artBool
            if ehrBool
                columnOut{i} = [artFeats, ehrFeats];
            else
                columnOut{i} = [artFeats];
            end
        elseif ehrBool
            columnOut{i} = [ehrFeats];
        else
            error('No data selected')
        end        
    end
end

function wvFeatureTable = appendEhrData(wvFeatureTable, wvFeatures, ehrFeatures)
% Append EHR data

    ehrBroken = breakCellsIntoColumns(ehrFeatures);
    [~, uIdx] = unique(ehrBroken(:, {'Sepsis_ID', 'Sepsis_EncID'}));
    ehrBroken = ehrBroken(uIdx, :);
    
    featList = ["Creatinine", "Glucose", "HCT", "Hgb", "INR", "Lactate", ...
                   "PLT", "Potassium", "Sodium", "WBC", "HR", "MAP", ...
                   "RespiratoryRate", "SpO2", "Temperature", "FiO2", "PEEP", ...
                   "Intubated", "UrineOutput", "Dobutamine", "Dopamine", ...
                   "Epinephrine", "Isoproterenol", "Milrinone", ...
                   "Norepinephrine", "Vasopressin"];
   featList = [featList, featList + "Retro"];
   fidx = ismember(featList, ehrBroken.Properties.VariableNames);
   featList = featList(fidx);
   
   % This preserves the order of trainIds (rather than innerjoin)
   ehrTrain = join(wvFeatures.trainIds, ehrBroken, ...
                    'LeftKeys', ["Ids", "EncID"], ...
                    'RightKeys', ["Sepsis_ID", "Sepsis_EncID"], ...
                    'RightVariables', featList);
                    
   ehrTest = join(wvFeatures.testIds, ehrBroken, ...
                   'LeftKeys', ["Ids", "EncID"], ...
                   'RightKeys', ["Sepsis_ID", "Sepsis_EncID"], ...
                   'RightVariables', featList);
    % GO through folds
    for k = 1:3
        kFoldEhrTrain = ehrTrain(wvFeatures.training_idxs(k, :), :);
        kFoldEhrValid = ehrTrain(~wvFeatures.training_idxs(k, :), :);
        for f = 1:length(featList)
            wvFeatureTable.Training_X{1} = [wvFeatureTable.Training_X{1}, ...
                                            cell2mat(kFoldEhrTrain.(featList(f)))];
            wvFeatureTable.Validation_X{1} = [wvFeatureTable.Validation_X{1}, ...
                                              cell2mat(kFoldEhrValid.(featList(f)))];
            wvFeatureTable.Test_X{1} = [wvFeatureTable.Test_X{1}, ...
                                        cell2mat(ehrTest.(featList(f)))];
        end
    end
             
end

function tableOfFeaturs = applyTtest(tableOfFeatures, pValCutoff)
    % Loop through folds
    for k = 1:3
        ttestResults = [];
        testPval = [];
        kTrain = tableOfFeatures{k, 'Training_X'}{1};
        nVars = size(kTrain, 2);
        kLabel = tableOfFeatures{k, 'Training_Y'}{1};
        kPos = kTrain(logical(kLabel), :);
        kNeg = kTrain(~logical(kLabel), :);
        for v = 1:nVars
            [~, p, ~, statsOut] = ttest2(kPos(:, v), kNeg(:, v), ...
                                         'Vartype', 'unequal');
            testPval(v) = p;
            ttestResults.stats(v) = statsOut;
        end
        varIdx = testPval <= pValCutoff;
        if all(~varIdx)
            error('No variables meet threshold')
        else
            tableOfFeatures{k, 'Training_X'}{1} = tableOfFeatures{k, 'Training_X'}{1}(:, varIdx);
            tableOfFeatures{k, 'Validation_X'}{1} = tableOfFeatures{k, 'Validation_X'}{1}(:, varIdx);
            tableOfFeatures{k, 'Test_X'}{1} = tableOfFeatures{k, 'Test_X'}{1}(:, varIdx);
        end
    end
    
end

function tableOfFeatures = applyMi(tableOfFeatures, nColumns)
    miValuesAll = getMutualInfoQuick(tableOfFeatures);
    for k = 1:3
        tableOfFeatures{k, 'Training_X'}{1} = tableOfFeatures{k, 'Training_X'}{1}(:, miValuesAll(k).ColumnIndex(1:nColumns));
        tableOfFeatures{k, 'Validation_X'}{1} = tableOfFeatures{k, 'Validation_X'}{1}(:, miValuesAll(k).ColumnIndex(1:nColumns));
        tableOfFeatures{k, 'Test_X'}{1} = tableOfFeatures{k, 'Test_X'}{1}(:, miValuesAll(k).ColumnIndex(1:nColumns));
    end 
end