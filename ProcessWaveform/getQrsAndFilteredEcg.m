function [qrsOut, ecgOut, hrvOut] = getQrsAndFilteredEcg(tableIn)
% Filter and scale available ECG signals within loaded table
%
% Olivia Alge for BCIL, April 2022.
% Matlab 2020b, Windows 10
%
% DESCRIPTION
% Filters and scales all ECG signals and returns them to output
%
% REQUIRES
% QRS_detection repository
%
% INPUT
% tableIn: table containing ECG signals, of format 
%          nRows x (SepsisID, Label, ECG)
% 
% OUTPUT
% ecgOut: tableIn, but with Signals processed
    
    fsEcg = 240;  % Sampling rate of ECG
    
    % Set up column indices
    idCol = 'SepsisID';
    encCol = 'Sepsis_EncID';
    labelCol = 'Label';
    signalCol = strcmp(tableIn.Properties.VariableNames, 'ECG');
    
    % Initialize tableOut
    nSignals = size(tableIn, 1);
    ecgOut = tableIn;
    ecgOut.Properties.VariableNames{signalCol} = 'Filtered_ECG';
    
    % Initialize hrvOut
    hrvOut = tableIn;
    hrvOut.Properties.VariableNames{signalCol} = 'HRV';
    
    % Initialize qrsOut
    qrsOut.(idCol) = 0;
    qrsOut.(encCol) = '';
    qrsOut.(labelCol) = 0;
    qrsOut(nSignals).QRS = [0,0];

    for i = 1:nSignals   
        iEcg = cell2mat(tableIn{i, 'ECG'});
        [iqrs, iFiltered] = qrs_detect(iEcg, fsEcg, 'harm', [], true, true);
        iHrv = diff(iqrs) / fsEcg;
        ecgOut{i, 'Filtered_ECG'} = {iFiltered};
        hrvOut{i, 'HRV'} = {iHrv};
        try
            qrsOut(i).(idCol) = ecgOut{i, idCol}{1};
            qrsOut(i).(encCol) = ecgOut{i, encCol}{1};
            qrsOut(i).(labelCol) = ecgOut{i, labelCol}{1};
        catch ME
            if strcmp(ME.identifier, 'MATLAB:cellRefFromNonCell')
                qrsOut(i).(idCol) = ecgOut{i, idCol};
                qrsOut(i).(encCol) = ecgOut{i, encCol};
                qrsOut(i).(labelCol) = ecgOut{i, labelCol};
            end
        end
        qrsOut(i).QRS = iqrs;
    end
end