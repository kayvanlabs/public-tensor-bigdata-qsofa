function [wvFeatureTable, featList] = appendEhrData(wvFeatureTable, ehrFeatures)
% Append EHR data

    ehrBroken = breakCellsIntoColumns(ehrFeatures);
    [~, uIdx] = unique(ehrBroken(:, {'Sepsis_ID', 'Sepsis_EncID'}));
    ehrBroken = ehrBroken(uIdx, :);
    
    featList = ["Creatinine", "Glucose", "HCT", "Hgb", "INR", "Lactate", ...
                   "PLT", "Potassium", "Sodium", "WBC", "HR", "MAP", ...
                   "RespiratoryRate", "SpO2", "Temperature", "FiO2", "PEEP", ...
                   "Intubated", "UrineOutput", "Dobutamine", "Dopamine", ...
                   "Epinephrine", "Isoproterenol", "Milrinone", ...
                   "Norepinephrine", "Vasopressin"];
   featList = [featList, featList + "Retro"];
   fidx = ismember(featList, ehrBroken.Properties.VariableNames);
   featList = featList(fidx);
   fidx = ismember(ehrBroken.Properties.VariableNames, featList);
   ehrMat = cell2mat(table2array(ehrBroken(:, fidx)));
   % Replace unknown value with 0
   ehrMat(isnan(ehrMat)) = 0;
   ehrCells = mat2cell(ehrMat, ones(1, size(ehrMat, 1)));
   ehrTable = table(ehrBroken.Sepsis_ID, ehrBroken.Sepsis_EncID, ehrCells, ...
                    'VariableNames', ["SepsisID", "Sepsis_EncID", "EHR_Data_Features"]);
   
  % This preserves the order (rather than innerjoin)
   wvFeatureTable = join(wvFeatureTable, ehrTable, ...
                         'LeftKeys', ["SepsisID", "Sepsis_EncID"], ...
                         'RightKeys', ["SepsisID", "Sepsis_EncID"]);
end