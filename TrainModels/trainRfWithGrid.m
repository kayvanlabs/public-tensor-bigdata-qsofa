function [bestResults, bestModel, allResults] = trainRfWithGrid(trainVector, setRank, metricToGrade, seed)
% Train random forest model with grid search to determine optimal
% parameters, then return trained model
    addpath('../../BCIL-Shared/AUC/');   % For Area under ROC curve
    addpath('../GeneralProcessing/')  % For Area under Precision Recall curve
    params = assignParams();
    params.split_seed = seed;
    bestResults = [];
    allResults = [];
    bestModel.rf = [];
    
    for i = 1:3  % 3FCV
        thisFold = trainVector.Fold == i;
        thisRank = trainVector.Rank == setRank;
        thisRow = thisFold & thisRank;
        % Select training, validation data
        trainData = trainVector{thisRow, 'Training_X'}{1};
        trainLabel = trainVector{thisRow, 'Training_Y'}{1};
        validData = trainVector{thisRow, 'Validation_X'}{1};
        validLabel = trainVector{thisRow, 'Validation_Y'}{1};
        % Reformat if needed
        if iscell(class(trainLabel))
            trainLabel = cell2mat(trainLabel);
            validLabel = cell2mat(validLabel);
        end
        % Train
        [resultsRf, modelRf, bestRow] = train_rf(trainData, validData, ...
                                                 trainLabel, validLabel, ...
                                                 metricToGrade, params);
        resultsRf = struct2table(resultsRf);
        allResults = [allResults; resultsRf];
        bestResults = [bestResults; resultsRf(bestRow, :)];
        bestModel(i).rf = modelRf;
    end
end

function params = assignParams()
    % Copied from load_model_params in DOD code
    % Random Forest Models
    params.rf_numTrees = [50, 75, 100];
    params.rf_MinLeafSize = [1, 5, 10, 15, 20];
    params.rf_MaxNumSplits_p = [0.25, 0.50, 0.75, 1];
    params.rf_splitCriterion = {'gdi'};
    params.rf_numPredictorsToSample = 10:10:100;
end

function [results, rfModel, maxRow] = train_rf(dataTrain,dataValid,labelsTrain,labelsValid, metricToGrade, params)
    %% Set up parameters
    nObs = size(dataTrain,1); % number of observations in the training set
    numTrees = params.rf_numTrees;
    MinLeafSize = params.rf_MinLeafSize;
    if isfield(params,'rf_MaxNumSplits_p')
        params.rf_MaxNumSplits = floor(params.rf_MaxNumSplits_p*(nObs-1));
        MaxNumSplits = params.rf_MaxNumSplits;
    else
        MaxNumSplits = params.rf_MaxNumSplits;
    end
    splitCriterion = params.rf_splitCriterion;
    numPredictorsToSample = params.rf_numPredictorsToSample;
    %% Fit the Random Forest to training data
    
    % Determine number of values to try for each model parameter
    nTreeIters = length(numTrees);
    nMinLeafIters = length(MinLeafSize);
    nMaxSplitIters = length(MaxNumSplits);
    nSplitIters = length(splitCriterion);
    nPredictorsIters = length(numPredictorsToSample);

    % Calculate total number of iterations for grid search
    nTrials = nTreeIters * nMinLeafIters * nMaxSplitIters * nSplitIters * ...
              nPredictorsIters;
          
    % Grid-search: try all combinations of the parameters
    if (params.split_seed == 0)
        rng('default');         % For backward compatibility
    else
        rng(params.split_seed); % For reproducibility
    end

    disp('Training random forest models');
    maxMetric = 0;

    row2Insert = 1;
    for aa = 1:nTreeIters
        for bb = 1:nMinLeafIters
            for cc = 1:nSplitIters
                for dd = 1:nPredictorsIters
                    for ee =1:nMaxSplitIters
                            Mdl = TreeBagger(numTrees(aa), ...
                                             dataTrain, ...
                                             labelsTrain, ...
                                             'OOBPrediction', 'On', ...
                                             'Method', 'classification', ...
                                             'MinLeafSize', MinLeafSize(bb), ...
                                             'MaxNumSplits', MaxNumSplits(ee), ...
                                             'SplitCriterion', splitCriterion{cc}, ...
                                             'NumPredictorsToSample', numPredictorsToSample(dd), ...
                                             'OOBPredictorImportance','on', ...
                                             'PredictorSelection','curvature');

                            results(row2Insert) = createResults(Mdl, ...
                                                    dataValid, labelsValid);
                            % Store each model and select parameters in struct
                            

                            %disp(num2str(row2Insert) + " of " + num2str(nTrials))
                            if (results(row2Insert).(metricToGrade) > maxMetric) || (row2Insert == 1)
                                rfModel = Mdl;
                                maxRow = row2Insert;
                                maxMetric = results(row2Insert).(metricToGrade);
                            end
                            row2Insert = row2Insert + 1;
                    end
                end
            end
        end
    end
end