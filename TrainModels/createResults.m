function [results] = createResults(Mdl, dataValid, labelsValid)
% DESCRIPTION 
% Create results struct using Mdl
    idxPos = 2;
    if isa(Mdl, 'LUCCK')
        scores = Mdl.predict(dataValid);
        Yfit = [];
    else
        [Yfit, scores]  = predict(Mdl, dataValid);
    end
    results.Yfit = Yfit;
    results.scores = scores;
    try
        % ROC_AUC metrics
        [X, Y, T, AUC, thresh, F1, sens, spec] = ROC_AUC(labelsValid, ...
                                                         scores(:,idxPos),...
                                                         'method', 3, ...
                                                         'DISPLAY_ROC',0);
        % Save to output
        results.X = X;
        results.Y = Y;
        results.T = T;
        results.Thresh = thresh;
        results.Recall = sens;
        results.Specificity = spec;
        results.F1_score = F1;
        results.ROC_AUC = AUC;

        % Precision-Recall
        [prAuc] = computePRCAUC(labelsValid', scores(:, idxPos)');
        [~, ~, prAucAlex] = PRC_AUC(labelsValid, scores(:, idxPos), ...
                                    'method', 3, ...
                                    'DISPLAY_PRC', 0);
        % Save to output
        results.PRC_AUC = prAuc;
        results.PRC_AUC_Alex = prAucAlex;
    catch ME
        if strcmp(ME.identifier, 'MATLAB:ROC_AUC:expectedNonNaN')
            warning('Scores have NaN values');
            results = assignForNan(results);
        else
            disp(ME.identifier)
        end
    end
    
    % Get model-specific results
    if isa(Mdl, 'TreeBagger')
        results = createRfSpecificResults(results, Mdl);
    elseif isa(Mdl, 'ClassificationSVM')
        results = createSvmSpecificResults(results, Mdl);
    elseif isa(Mdl, 'LUCCK')
        results = createLucckSpecificResults(results, Mdl);
    end
end

function results = createRfSpecificResults(results, Mdl)
% DESCRIPTION
% Adds random forest-specific results to results struct
% MODIFIES
% results
    results.oobError = oobError(Mdl);
    results.featureImportance = Mdl.OOBPermutedPredictorDeltaError;

    [min_oobError, nTrees_min_oobError] = min(oobError(Mdl));
    results.min_oobError = min_oobError;
    results.nTrees_min_oobError = nTrees_min_oobError;

    results.numTrees = Mdl.NumTrees;
    results.MinLeafSize = Mdl.MinLeafSize;
    critIdx = find(strcmp(Mdl.TreeArguments, 'SplitCriterion')) + 1;
    results.splitCriterion = Mdl.TreeArguments{critIdx};
    results.numPredictorsToSample = Mdl.NumPredictorsToSample;
    splitIdx = find(strcmp(Mdl.TreeArguments, 'MaxNumSplits')) + 1;
    results.MaxNumSplits =  Mdl.TreeArguments{splitIdx};
    nObs = size(Mdl.X, 1);
    results.rf_MaxNumSplits_p = round(results.MaxNumSplits / (nObs-1), 2);
end

function results = createSvmSpecificResults(results, Mdl)
% DESCRIPTION
% Adds SVM-specific results to results struct
% MODIFIES
% results
    results.kernelFunction = Mdl.ModelParameters.KernelFunction;
    results.kernelScale = Mdl.ModelParameters.KernelScale;
    results.boxConstarint = Mdl.ModelParameters.BoxConstraint;
    results.solver = Mdl.ModelParameters.Solver;
    results.outlierFraction = Mdl.ModelParameters.OutlierFraction;
end

function results = createLucckSpecificResults(results, Mdl)
% DESCRIPTION
% Adds LUCCK-specific results to results struct
% MODIFIES
% results
    results.lambda = Mdl.Lambda;
    results.theta = Mdl.Theta;
end

function results = assignForNan(results)
% DESCRIPTION
% Assigns nan output to results if scores are nan
    results.X = nan;
    results.Y = nan;
    results.T = nan;
    results.Thresh = nan;
    results.Recall = nan;
    results.Specificity = nan;
    results.F1_score = nan;
    results.ROC_AUC = nan;
    results.PRC_AUC = nan;
    results.PRC_AUC_Alex = nan;
end