function [bestValidationResults, bestModels, testResults, allResults] = mergeResultsFromSlurm(dirIn, outName)
% DESCRIPTION
% Merge results from SLURM array task
    baseName = 'data_';
    dirFiles = dir(fullfile(dirIn, strcat(baseName, '*.mat')));
    bestValidationResults = [];
    bestModels = [];
    testResults = [];
    allResults = [];
    nIters = size(dirFiles, 1);
    for i = 1:nIters
        iFile = load(fullfile(dirIn, dirFiles(i).name));
        bestModels = [bestModels; iFile.bestModels];
        bestValidationResults = [bestValidationResults; iFile.bestValidationResults];
        testResults = [testResults; iFile.testResults];
        allResults = [allResults; iFile.allResults];
        if ~mod(i, 10)
            disp(strcat("Merging ", num2str(i), " of ", num2str(nIters)));
        end
    end
    save(fullfile(dirIn, strcat(outName, '.mat')), 'bestValidationResults', ...
          'bestModels', 'testResults', 'allResults', '-v7.3');
    disp('Completed merging');
    viewResults(bestValidationResults, testResults);
end

function viewResults(bestValidationResults, testResults)
    mean((bestValidationResults{:, ["F1_score", "Recall", "Specificity", "ROC_AUC", "PRC_AUC"]}))
    std((bestValidationResults{:, ["F1_score", "Recall", "Specificity", "ROC_AUC", "PRC_AUC"]}))
    
    mean((testResults{:, ["F1_score", "Recall", "Specificity", "ROC_AUC", "PRC_AUC"]}))
    std((testResults{:, ["F1_score", "Recall", "Specificity", "ROC_AUC", "PRC_AUC"]}))
    %mean(testResults{:, ["F1_score_Harm", "Recall_Harm", "Specificity_Harm", "AUC_score_Harm", "AUC_PRC"]})
    %std(testResults{:, ["F1_score_Harm", "Recall_Harm", "Specificity_Harm", "AUC_score_Harm", "AUC_PRC"]})
end