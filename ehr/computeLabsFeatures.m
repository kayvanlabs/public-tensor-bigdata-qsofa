function [labsFeatures] = computeLabsFeatures(patientLabs)
% Compute features related to labs
%
% Olivia Alge for BCIL, March 2020.
% Matlab 2019a, Windows 10
%
% DESCRIPTION
% Compute features from labs and store in a table. Features
% computed include:
%
% INPUT
% patientLabs: table from ehr data labs, only for one SepsisID
%
% OUTPUT
% labsFeatures: table of features taken from labs table
%
% TODO: define labsFeatures
    uniqueDates = unique(patientLabs.ActivityDate);
    for i = 1:length(uniqueDates)
        iDate = uniqueDates(i);
        iDateTable = patientLabs(patientLabs.ActivityDate == iDate, :);
    end
    labsFeatures = [];
end

function plateletTable = computePlateletScore(patientLabs)
    % platelet score from Sepsis-3
    plateletCounts = patientLabs(strcmp(patientLabs.RESULT_NAME, 'Platelet Count'), :);
    plateletCountValues = str2num(cell2mat(plateletCounts.VALUE));
    % fix relations
    plateletScore4 = (plateletCountValues < 20) * 4;
    plateletScore3 = (plateletCountValues < 50) * 3;
    plateletScore2 = (plateletCountValues < 100) * 2;
    plateletScore1 = (plateletCountValues < 150) * 1;
    plateletScore = plateletScore1 + plateletScore2 + plateletScore3 + plateletScore4;
    plateletTable = [plateletCounts, table(plateletScore)];
end

function biliTable = computeBilirubinScore(patientLabs)
    biliToCompute = obtainBilirubinValues(patientLabs);
    % assumes bilirubin is measured in mg/dL
    % score from sepsis-3
    biliValues = str2num(cell2mat(biliToCompute.VALUE));
    biliScore4 = (12 <= biliValues) * 4;
    biliScore3 = ((6 <= biliValues) & (biliValues < 12)) * 3;
    biliScore2 = ((2 <= biliValues) & (biliValues < 6)) * 2;
    biliScore1 = (1.2 <= biliValues) & (biliValues < 2) * 1;
    biliScore = biliScore1 + biliScore2 + biliScore3 + biliScore4;
    biliTable = [biliToCompute, table(biliScore)];
end

function bilirubinNumeric = obtainBilirubinValues(patientLabs)
    % Find values of total bilirubin level
    bilirubinIndices = strcmp(patientLabs.RESULT_NAME, 'BILIRUBIN, TOTAL');
    bilirubinTotal = patientLabs(bilirubinIndices, :);
    
    % Select bilirubin measurements which are numeric, and don't have text.
    % Numeric entries are 3 characters in length.
    entryLengths = cellfun(@length, bilirubinTotal.VALUE, ...
                           'UniformOutput', true);
                       
    bilirubinNumeric = bilirubinTotal(entryLengths == 3, :);
end

function creTable = computeCreatinineScore(patientLabs)
    % assumes measurement in mg/dL
    % score from sepsis-3
    nonRelationalCreLevel = obtainCreatinineLevel(patientLabs);
    creValues = str2num(cell2mat(nonRelationalCreLevel.VALUE));
    % TODO: Incorporate relational
    creScore4 = (5 <= creValues) * 4;
    creScore3 = ((3.5 <= creValues) & (creValues < 5)) * 3;
    creScore2 = ((2 <= creValues) & (creValues < 3.5)) * 2;
    creScore1 = ((1.2 <= creValues) & (creValues < 2)) * 1;
    creScore = creScore1 + creScore2 + creScore3 + creScore4;
    creTable = [nonRelationalCreLevel, table(creScore)];
    
    % Find creatinine levels using relational operators
    creIndices = strcmp(patientLabs.RESULT_NAME, 'CREATININE LEVEL');
    creatinineLevel = patientLabs(creIndices, :);
    relationalOperators = ["<", ">"];
    areRelational = contains(creatinineLevel.VALUE, relationalOperators);
    relationalCreLevel = creatinineLevel(areRelational, :);
    if ~isempty(relationalCreLevel)
        if all(strcmp(relationalCreLevel.VALUE, '<0.10'))
            creScore = zeros(size(relationalCreLevel, 1), 1);
            relationalCreLevel = [relationalCreLevel, table(creScore)];
            creTable = [creTable; relationalCreLevel];
        else
            error(['TODO: Fix computeCreatinineScore to handle '...
                   'additional relations']) 
        end
    end
end

function creLevel = obtainCreatinineLevel(patientLabs)
% Obtain creatinine levesl that do not have relational operators
    creIdx = strcmp(patientLabs.RESULT_NAME, 'CREATININE LEVEL');
    creObservations = patientLabs(creIdx, :);
    relationalOperators = ["<", ">"];
    areRelational = contains(creObservations.VALUE, relationalOperators);
    creLevel = creObservations(~areRelational, :);
end

function bunObservations = obtainBloodUreaNitrogen(patientLabs)
% obtain blood urea nitrogen
    bunIdx = strcmp(patientLabs.RESULT_NAME, 'UREA NITROGEN');
    % make sure it comes from blood
    bunIdx = bunIdx & strcmp(patientLabs.SPECIMENSOURCE_CODE, 'BLD');
    bunObservations = patientLabs(bunIdx, :);
    
    relationalOperators = ["<", ">"];
    areRelational = contains(bunObservations.VALUE, relationalOperators);
    bunObservations = bunObservations(~areRelational, :);
end

% function creScoreForRow = findCreScore(tableRow)
%     isLessThan = contains(tableRow.VALUE, '<');
%     if isLessThan
%         splitValue = strsplit(char(tableRow.VALUE), '<');
%         splitValue = str2double(splitValue{2});
%     end
% end

function biliCr = computeBiliCr(patientLabs)
% Measure ratio of bilirubin to creatinine levels
% TODO: test this more thoroughly
    bilirubinTotal = obtainBilirubinValues(patientLabs);
    creatinineLevel = obtainCreatinineLevel(patientLabs);
    
    biliCr = [];
    % find comprehensive metabolic panel  
    compMetPanel = 'Comprehensive Metabolic Panel';
    biliPanel = strcmp(bilirubinTotal.ORDER_NAME, compMetPanel);
    crePanel = strcmp(creatinineLevel.ORDER_NAME, compMetPanel);
    
    bilirubinTotal = bilirubinTotal(biliPanel, :);
    creatinineLevel = creatinineLevel(crePanel, :);

    for i = 1:size(bilirubinTotal, 1)
        currentBili = [];
        currentCre = [];
        currentBili = bilirubinTotal(i, :);
        biliOrderDate = currentBili.ORDER_DATE;
        creIdx = creatinineLevel.ORDER_DATE == biliOrderDate;
        if any(creIdx)
            currentCre = creatinineLevel(creIdx, :);
            biliCrRatio = str2double(currentBili.VALUE) / ...
                          str2double(currentCre.VALUE);
            currentBili = [currentBili, table(biliCrRatio)];
            currentCre = [currentCre, table(biliCrRatio)];
            biliCr = [biliCr; currentBili; currentCre];
        end
    end
end

function bunCr = computeBunCr(patientLabs)
% Measure ratio of blood urea nitrogen to creatinine levels
% TODO: test this more thoroughly
    bunLevel = obtainBloodUreaNitrogen(patientLabs);
    creatinineLevel = obtainCreatinineLevel(patientLabs);
    
    bunCr = [];

    for i = 1:size(bunLevel, 1)
        currentBun = [];
        currentCre = [];
        currentBun = bunLevel(i, :);
        bunOrderDate = currentBun.ORDER_DATE;
        creIdx = creatinineLevel.ORDER_DATE == bunOrderDate;
        if any(creIdx)
            currentCre = creatinineLevel(creIdx, :);
            bunCrRatio = str2double(currentBun.VALUE) / ...
                          str2double(currentCre.VALUE);
            currentBun = [currentBun, table(bunCrRatio)];
            currentCre = [currentCre, table(bunCrRatio)];
            bunCr = [bunCr; currentBun; currentCre];
        end
    end
end