function tableIn = breakCellsIntoColumns(tableIn)
% separate cells into array values
    cellArrList = ["Creatinine", "Glucose", "HCT", "Hgb", "INR", "Lactate", ...
                   "PLT", "Potassium", "Sodium", "WBC", "HR", "MAP", ...
                   "RespiratoryRate", "SpO2", "Temperature", "FiO2", "PEEP", ...
                   "Intubated", "UrineOutput", "Dobutamine", "Dopamine", ...
                   "Epinephrine", "Isoproterenol", "Milrinone", ...
                   "Norepinephrine", "Vasopressin"];
   cellArrList = [cellArrList, cellArrList + "Retro"];
   cellArridx = ismember(cellArrList, tableIn.Properties.VariableNames);
   cellArrList = cellArrList(cellArridx);
   
   for i = 1:length(cellArrList)
       iArr = cellArrList(i);
       iRow = (cellfun(@cell2mat, tableIn.(iArr), 'UniformOutput', false));
       tableIn.(iArr) = iRow;
   end
end