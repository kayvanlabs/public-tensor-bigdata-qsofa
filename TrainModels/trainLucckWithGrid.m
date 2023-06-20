function [bestResults, bestModel, allResults] = trainLucckWithGrid(trainVector, setRank, metricToGrade, seed)
% Train LUCCK model with grid search to determine optimal
% parameters, then return trained model
% Adapted from Larry Hernandez's trainFlexibleNonConvex.m
    addpath('../../BCIL-Shared/AUC/');   % For Area under ROC curve
    addpath('../GeneralProcessing/')  % For Area under Precision Recall curve
    addpath('../../flexconvexkernels/');  % For LUCCK
    
    modelVar = 'lucck';
    params = assignParams();
    params.split_seed = seed;
    bestResults = [];
    allResults = [];
    bestModel.(modelVar) = [];
    
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
        [resultsLucck, modelLucck, bestRow] = trainLucck(trainData, validData, ...
                                                          trainLabel, validLabel, ...
                                                          metricToGrade, params);
        resultsLucck = struct2table(resultsLucck);
        allResults = [allResults; resultsLucck];
        bestResults = [bestResults; resultsLucck(bestRow, :)];
        bestModel(i).(modelVar) = modelLucck;
    end
end

function params = assignParams()
    params.theta = 0.01:0.01:0.1;  % range for Theta model parameter
    params.lambda = 0.1:0.10:1.0;  % range for Lambda model parameter
end

function [results, lucckModel, maxRow] = trainLucck(dataTrain, dataValid, labelsTrain, labelsValid, metricToGrade, params)
    % The relative distributions of train and test sets are the same so
    % trainWeight should be ones:
    trainWeight = ones(size(dataTrain, 1), 1);

    % Obtain the unique set of classes from the labels
    labelsTrainChar = cellstr(num2str((labelsTrain)));
    classes = unique(labelsTrainChar);
    
    % Calculate total number of iterations for grid search
    nLambda = length(params.lambda);
    nTheta = length(params.theta);
    nTrials =  nLambda * nTheta;
          
    % Grid-search: try all combinations of the parameters
    if (params.split_seed == 0)
        rng('default');         % For backward compatibility
    else
        rng(params.split_seed); % For reproducibility
    end
    
    disp('Training LUCCK models');
    maxMetric = 0;
    maxRow = 1;
    
    row2Insert = 1;
    for iLambda = 1:nLambda
        for jTheta = 1:nTheta
            Mdl = LUCCK(dataTrain, labelsTrainChar, classes, ...
                        params.lambda(iLambda), params.theta(jTheta), ...
                        trainWeight);
            results(row2Insert) = createResults(Mdl, dataValid, labelsValid);
            if results(row2Insert).(metricToGrade) > maxMetric || (row2Insert == (nLambda * nTheta))
                lucckModel = Mdl;
                maxRow = row2Insert;
                maxMetric = results(row2Insert).(metricToGrade);
            end
            row2Insert = row2Insert + 1;
        end
    end
end