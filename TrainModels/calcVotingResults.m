function resultsFromTest = calcVotingResults(bestModels, tableOfFeatures, setRank)
    % Use voting to determine final test prediction
    
    modelField = fieldnames(bestModels);
    modelField = modelField{1};
    results = [];
    posIdx = 2;
    
    % Loop through CV folds
    for k = 1:3
        thisFold = tableOfFeatures.Fold == k;
        thisRank = tableOfFeatures.Rank == setRank;
        thisRow = thisFold & thisRank;
        testData = tableOfFeatures{thisRow, 'Test_X'}{1};
        testLabel = tableOfFeatures{thisRow, 'Test_Y'}{1};
        if iscell(class(testLabel))
            testLabel = cell2mat(testLabel);
        end
        kModel = bestModels(k).(modelField);
        
        if isa(kModel, 'LUCCK')
            scores = predict(kModel, testData);
            Yfit = [];
        else
            [Yfit, scores]  = predict(kModel, testData);
        end        
%        results(k).Yfit = Yfit;
        results = [results, scores(:, posIdx)];
    end
    votingResults = median(results, 2);
    [X,Y,T,AUC,thresh,F1,sens,spec,~] = ROC_AUC(testLabel, votingResults,...
                                                'method', 3, 'DISPLAY_ROC', 0);
    [prAuc] = computePRCAUC(testLabel', votingResults');
    resultsFromTest.ROC_AUC = AUC;
    resultsFromTest.F1_score = F1;
    resultsFromTest.Recall = sens;
    resultsFromTest.Specificity = spec;
    resultsFromTest.PRC_AUC = prAuc;
    resultsFromTest = struct2table(resultsFromTest);
end