opts = spreadsheetImportOptions('NumVariables', 15);
opts.VariableNamesRange = 'B1:P1';
opts.DataRange = 'B2:P105';
opts.VariableTypes = ["string", repelem("logical", 3), 'string', repelem("double", 10)];

baseFile = 'Z:\Projects\Tensor_Sepsis\Models\qSOFA\ecg_art_ehr\progressive_qsofa2_viz.xlsx';
rfTestResults = readtable(baseFile, opts, 'Sheet', 'RF Testing Results (VOTE)');
svmTestResults = readtable(baseFile, opts, 'Sheet', 'SVM Testing Results (VOTE)');
svmTestResults = svmTestResults(1:93, :);
lucckTestResults = readtable(baseFile, opts, 'Sheet', 'LUCCK Testing Results (VOTE)');
lucckTestResults = lucckTestResults(1:93, :);


xVarNames = ["No tensor reduction", "2", "3", "4"];
xVar = [1, 3:5];
yVar = 0:0.1:1;

hrs = ["6 hrs", "12 hrs"];

% Signals Only
sigOnly = ~rfTestResults.EHR & rfTestResults.ArtLine & rfTestResults.ECG;
signalsOnlyRf6 = rfTestResults(sigOnly & ismember(rfTestResults.Gap, hrs(1)), :);
signalsOnlyRf12 = rfTestResults(sigOnly & ismember(rfTestResults.Gap, hrs(2)), :);

% EHR only
ehrOnly = rfTestResults.EHR & ~rfTestResults.ArtLine & ~rfTestResults.ECG;
ehrOnlyRf6 = rfTestResults(ehrOnly & ismember(rfTestResults.Gap, hrs(1)), :);
ehrOnlyRf12 = rfTestResults(ehrOnly & ismember(rfTestResults.Gap, hrs(2)), :);
ehrOnly = svmTestResults.EHR & ~svmTestResults.ArtLine & ~svmTestResults.ECG;
ehrOnlySvm6 = svmTestResults(ehrOnly & ismember(svmTestResults.Gap, "6hrs"), :);
ehrOnlySvm12 = svmTestResults(ehrOnly & ismember(svmTestResults.Gap, "12hrs"), :);
ehrOnly = lucckTestResults.EHR & ~lucckTestResults.ArtLine & ~lucckTestResults.ECG;
ehrOnlyLk6 = lucckTestResults(ehrOnly & ismember(lucckTestResults.Gap, "6hrs"), :);
ehrOnlyLk12 = lucckTestResults(ehrOnly & ismember(lucckTestResults.Gap, "12hrs"), :);


% ECG only
ecgOnly = ~rfTestResults.EHR & ~rfTestResults.ArtLine & rfTestResults.ECG;
ecgOnlyRf6 = rfTestResults(ecgOnly & ismember(rfTestResults.Gap, hrs(1)), :);
ecgOnlyRf12 = rfTestResults(ecgOnly & ismember(rfTestResults.Gap, hrs(2)), :);

% ignore rank 1
signalsOnlyRf6 = signalsOnlyRf6(xVar, :);
signalsOnlyRf12 = signalsOnlyRf12(xVar, :);
ecgOnlyRf6 = ecgOnlyRf6(xVar, :);
ecgOnlyRf12 = ecgOnlyRf12(xVar, :);


%%
% EHR results
colorsForBars = [0, 0.45, 0.7; 0.8, 0.4, 0; 0.95, 0.9, 0.25];
vals = ["F1Mean", "RecallMean", "SpecificityMean", "AUCROCMean"];
valsS = ["F1SD", "RecallSD", "SpecificitySD", "AUCROCSD"];
figure;
tiledlayout(2,2);
titles = ["F1 Score", "Sensitivity", "Specificity", "AUROC"];

% 6-hour data
for i = 1:4
    nexttile;
    b = bar(1:3, [ehrOnlyRf6{1, vals(i)}, ehrOnlySvm6{1, vals(i)}, ...
            ehrOnlyLk6{1, vals(i)}]);
    b.FaceColor = 'flat';
    b.CData = colorsForBars;
    ylim([0,1]);
    hold on;
    errorbar([b.XEndPoints], [b.YData], [ehrOnlyRf6{1, valsS(i)}, ...
              ehrOnlySvm6{1, valsS(i)}, ehrOnlyLk6{1, valsS(i)}], ...
              'Color', 'black', 'LineStyle', 'none');
    title(titles(i));
    xticklabels(["RF", "SVM", "LUCCK"])
    hold off;
end

% 12-hour data
for i = 1:4
    nexttile;
    b = bar(1:3, [ehrOnlyRf12{1, vals(i)}, ehrOnlySvm12{1, vals(i)}, ...
            ehrOnlyLk12{1, vals(i)}]);
    b.FaceColor = 'flat';
    b.CData = colorsForBars;
    ylim([0,1]);
    hold on;
    errorbar([b.XEndPoints], [b.YData], [ehrOnlyRf12{1, valsS(i)}, ...
              ehrOnlySvm12{1, valsS(i)}, ehrOnlyLk12{1, valsS(i)}], ...
              'Color', 'black', 'LineStyle', 'none');
    title(titles(i));
    xticklabels(["RF", "SVM", "LUCCK"])
    hold off;
end


%% signal data
xVar = 1:4;

meanVal = 'F1Mean'; %'AUCROCMean'; %
sdVal = 'F1SD'; %'AUCROCSD'; %
score =  'F1 Score'; %'AUROC'; %


% Art + ECG
figure;
b = bar([xVar], [signalsOnlyRf6.(meanVal)'; signalsOnlyRf12.(meanVal)']);
hold on;
errorbar(reshape([b.XEndPoints], 4, 2)', reshape([b.YData], 4, 2)', ...
         [signalsOnlyRf6.(sdVal)'; signalsOnlyRf12.(sdVal)'], ...
         'LineStyle', 'none', 'Color', 'black'); 
%xlim([0.75, 4.25])
ylim([0,1]);
xticks(xVar);
xticklabels(xVarNames);
title([score, ' across CP Decomposition Rank'])
legend(hrs)
hold off;

% ECG only
figure;
b = bar([xVar], [ecgOnlyRf6.(meanVal)'; ecgOnlyRf12.(meanVal)']);
hold on;
errorbar(reshape([b.XEndPoints], 4, 2)', reshape([b.YData], 4, 2)', ...
         [ecgOnlyRf6.(sdVal)'; ecgOnlyRf12.(sdVal)'], ...
         'LineStyle', 'none', 'Color', 'black'); 
%xlim([0.75, 4.25])
ylim([0,1]);
xticks(xVar);
xticklabels(xVarNames);
title([score, ' across CP Decomposition Rank'])
legend(hrs)
hold off;


%Art + ECG + EHR
figure;
sigAndEHR = rfTestResults.EHR & rfTestResults.ArtLine & rfTestResults.ECG;
signalsEHRrf6 = rfTestResults(sigAndEHR & ismember(rfTestResults.Gap, hrs(1)), :);
signalsEHRrf12 = rfTestResults(sigAndEHR & ismember(rfTestResults.Gap, hrs(2)), :);
signalsEHRrf6(2,:) = [];
signalsEHRrf12(2,:) = [];
b = bar([xVar], [signalsEHRrf6.(meanVal)'; signalsEHRrf12.(meanVal)']);
ylim([0,1]);
hold on;
errorbar(reshape([b.XEndPoints], 4, 2)', reshape([b.YData], 4, 2)', ...
         [signalsEHRrf6.(sdVal)'; signalsEHRrf12.(sdVal)'], ...
         'LineStyle', 'none', 'Color', 'black');
hold off;
xticks(xVar);
xticklabels(xVarNames);
legend(hrs)
title([score, ' across CP Decomposition Rank']);

% comparing 6 hour to 12 hour data for tenred rank 2 and ehr only
rank2idx = 2;
for i = 1:4
    nexttile;
    xvals1 = [signalsOnlyRf6{rank2idx, vals(i)}, signalsOnlyRf12{rank2idx, vals(i)}];
    xvals2 = [ehrOnlyRf6{1, vals(i)}, ehrOnlyRf12{1, vals(i)}];
    b = bar(1:2, [xvals1; xvals2]);
    xtl = ["Rank 2 Signal Features", "EHR Data"];
    xticklabels(xtl);
    ylim([0,1]);
    hold on;
    %xticklabels();
    errorbar(reshape([b.XEndPoints], 2, 2)', reshape([b.YData], 2, 2)', ...
         [signalsOnlyRf6{rank2idx, valsS(i)}, signalsOnlyRf12{rank2idx, valsS(i)}; ...
          ehrOnlyRf6{1, valsS(i)}, ehrOnlyRf12{1, valsS(i)}], ...
         'LineStyle', 'none', 'Color', 'black'); 
    title(titles(i));
    hold off;
end
legend(["6 hours", "12 hours"])
