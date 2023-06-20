function [tableIn] = changeColNameWithIndex(tableIn, colNum, newColName)
% DESCRIPTION
% Simple function to change a column name in a table
%
% REQUIRES
% tableIn is not empty
% colNum is a scalar >= 1
% newColName is a valid column name for Matlab
%
% INPUT
%   tableIn: table with column name to change
%   colNum: numeric, column index in tableIn of column to change
%   newColName: string/char, new column name to give to tableIn
%
% OUTPUT
%   tableIn: tableIn but MODIFIED so that its column name is changed
    tableIn.Properties.VariableNames{colNum} = char(newColName);
end