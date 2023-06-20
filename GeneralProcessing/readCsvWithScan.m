function dataVec = readCsvWithScan(fileToRead)
% Read in one-row CSV file and output as row vector
%
% Olivia Alge for BCIL, January 2020.
% Matlab 2019a, Windows 10
%
% DESCRIPTION
% readMatrix() will not always work with large .csv files. This script
% uses sscanf to parse the data, then stores the output in one
% row vector for use with DOD-processing scripts.
%
% INPUT
% fileToRead: character vector, specifies .csv file to read in
%   ** EXPECTS ** data in fileToRead is only 1 row 
%
% OUTPUT
% dataVec: row vector of signal data contained in fileToRead
% Code adapted from the following resource:
% https://www.mathworks.com/matlabcentral/answers/231857-loading-large-csv-files

    if ~isfile(fileToRead)
        error('File does not exist')
    end

    % Open file
    fId = fopen(fileToRead);
    
    % Parse
    lineIn = fgetl(fId);
    dataVec = sscanf(lineIn, '%f,')';
    
    % Close file
    fclose(fId);
    % save('data.mat', 'dataVec'); 
end

