function [bestResults, bestModel, allResults] = trainSvmWithGrid(trainVector, setRank, metricToGrade, seed)
% Train SVM model with grid search to determine optimal
% parameters, then return trained model
    addpath('../../BCIL-Shared/AUC/');   % For Area under ROC curve
    addpath('../GeneralProcessing/')  % For Area under Precision Recall curve
    
    modelVar = 'svm';
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
        [resultsSvm, modelSvm, bestRow] = trainSvm(trainData, validData, ...
                                                   trainLabel, validLabel, ...
                                                   metricToGrade, params);
        resultsSvm = struct2table(resultsSvm);
        allResults = [allResults; resultsSvm];
        bestResults = [bestResults; resultsSvm(bestRow, :)];
        bestModel(i).(modelVar) = modelSvm;
    end
end

function params = assignParams()
    params.svm_KernelFunction = 'linear';% {'linear', 'rbf'}
    params.svm_KernelScale = logspace(-12, 12, 49); 
    params.svm_BoxConstraint = logspace(-7, 12, 39); % Going -8 or less crashes
    params.svm_Solver = 'SMO'; % Going ISDA may crash
    params.svm_OutlierFraction = 0;
end

function [results, svmModel, maxRow] = trainSvm(dataTrain, dataValid, labelsTrain, labelsValid, metricToGrade, params)
    % Grid-search: try all combinations of the parameters
    if (params.split_seed == 0)
        rng('default');         % For backward compatibility
    else
        rng(params.split_seed); % For reproducibility
    end
    
    % Calculate total number of iterations for grid search
    nKernelScale = length(params.svm_KernelScale);
    nBoxConstraint = length(params.svm_BoxConstraint);
    nTrials = nKernelScale * nBoxConstraint;
    
    disp('Training SVM models');
    maxMetric = 0;
    maxRow = 1;
    
    row2Insert = 1;
    for iKernelScale = 1:nKernelScale
        for jBoxConst = 1:nBoxConstraint
            Mdl = fitcsvm(dataTrain, labelsTrain, ...
                          'KernelFunction', params.svm_KernelFunction, ...
                          'BoxConstraint', params.svm_BoxConstraint(jBoxConst), ...
                          'KernelScale', params.svm_KernelScale(iKernelScale), ...
                          'Solver', params.svm_Solver, ...
                          'OutlierFraction', params.svm_OutlierFraction);
            results(row2Insert) = createResults(Mdl, dataValid, labelsValid);
            if (results(row2Insert).(metricToGrade) > maxMetric)
                svmModel = Mdl;
                maxRow = row2Insert;
                maxMetric = results(row2Insert).(metricToGrade);
            end
            row2Insert = row2Insert + 1;
        end
    end
end