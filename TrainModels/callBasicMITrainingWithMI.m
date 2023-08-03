function [bestValidationResults, bestModels, testResults, allResults] = callBasicMITrainingWithMI(baseFolder, useRank, useEhr, sDir, expName, modelType, varargin)
    baseFile = 'feature_vectors_';
    % expName = 'prediction_360_minutes_signal_10_minutes_ECG_Art';
    fname = 'feature_vectors';
    useMetric = 'F1_score';
    bestValidationResults = [];
    bestModels = [];
    testResults = [];
    allResults = [];
    
    % For selecting waveform types
    useArt = true;
    useEcg = true;
    
    % Set up iterations
    seedValues = 0:99;
    if isempty(getenv('SLURM_JOB_ID'))
        seedValues = varargin{1};
        trial = seedValues;
        disp(strcat("Using seedValues: ", num2str(seedValues)));
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
    save(fullfile(sDir, strcat('results_', num2str(i), '.mat')), ...
         'bestValidationResults', 'bestModels', 'testResults', 'allResults', ...
         '-v7.3');
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
