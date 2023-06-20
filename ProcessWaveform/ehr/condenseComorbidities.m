function condensedTable = condenseComorbidities(comorbiditiesTable)
% Condense the comorbidities table
%
% Olivia Alge for BCIL, February 2020.
% Matlab 2019a, Windows 10
%
% DESCRIPTION
% Condenses comorbiditiesTable, which has header rows, sepsis ID, and
% comorbidities are represented by 0, 1, or -99. This removes the -99
% entries and only keeps the 0/1 entries. Also removes the algorithm
% column, as the algorithms are the same across all rows. Also removes
% duplicated rows.
%
% INPUT
% comorbiditiesTable: 1080x34 table, from EHR data. Columns 4-33 are
%                     comorbidities data, first column is sepsis ID, 
%                     final column is activity date
% 
% OUTPUT
% condensedTable: table with headers, 0/1 data, sepsis ID, Activity date

    cmbMat = table2array(comorbiditiesTable(:, 4:33));
    % columns that have at least 1 comorbidity appearing
    posComorbidCols = logical(sum(cmbMat ~= 1) - size(cmbMat, 1));
    rows2select = sum(cmbMat, 2) ~= (-99 * size(cmbMat, 2));
    condensedTable = comorbiditiesTable(rows2select, :);
    cols2select = [true, false, false, posComorbidCols, true];
    condensedTable = condensedTable(:, cols2select);
    % remove redundant rows
    condensedTable = unique(condensedTable, 'rows', 'stable');
end