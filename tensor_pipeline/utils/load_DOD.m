function [data, params] = load_DOD(features)
    data = table([],[],[],[],'VariableNames',{'Ids','Labels','Tensors','Non-Tensor-Features'});
    for row = 1:length(features)
        
        id = features(row).DoD_ID;
        label = features(row).Label;
        
        % Tensors
        HRV = features(row).TautString_HRV;
        ECG = features(row).TautString_ECG;
        DTCWPT = features(row).DTCWPT;
        Art = features(row).Art;
        Spo2 = features(row).Spo2;
        
        % Non-Tensor Features

         % Creatinine
         Creatinine = [features(row).Creatinine{1} features(row).Creatinine{2} features(row).Creatinine{3} features(row).Creatinine{4} features(row).Creatinine{5}];
         % Glucose
         Glucose = [features(row).Glucose{1} features(row).Glucose{2} features(row).Glucose{3} features(row).Glucose{4} features(row).Glucose{5}];
         % HCT
         HCT = [features(row).HCT{1} features(row).HCT{2} features(row).HCT{3}           features(row).HCT{4}         features(row).HCT{5}];
         % Hgb
         Hgb = [features(row).Hgb{1} features(row).Hgb{2}         features(row).Hgb{3}           features(row).Hgb{4}         features(row).Hgb{5}];
         % INR
         INR = [features(row).INR{1} features(row).INR{2}         features(row).INR{3}           features(row).INR{4}         features(row).INR{5}];
         % Lactate
         Lactate = [features(row).Lactate{1}       features(row).Lactate{2}         features(row).Lactate{3}       features(row).Lactate{4}         features(row).Lactate{5}];
         % PLT
         PLT = [features(row).PLT{1}           features(row).PLT{2}         features(row).PLT{3}           features(row).PLT{4}         features(row).PLT{5}];
         % Potassium
         Potassium = [features(row).Potassium{1}     features(row).Potassium{2}         features(row).Potassium{3}     features(row).Potassium{4}         features(row).Potassium{5}];
         % Sodium
         Sodium = [features(row).Sodium{1}        features(row).Sodium{2}         features(row).Sodium{3}        features(row).Sodium{4}         features(row).Sodium{5}];
         % WBC
         WBC = [features(row).WBC{1}           features(row).WBC{2}         features(row).WBC{3}           features(row).WBC{4}         features(row).WBC{5}];
         % SpO2
         SpO2 = [features(row).SpO2{1}          features(row).SpO2{2}         features(row).SpO2{3}          features(row).SpO2{4}         features(row).SpO2{5}];
         % Temperature
         Temperature = [features(row).Temperature{1}   features(row).Temperature{2}         features(row).Temperature{3}   features(row).Temperature{4}         features(row).Temperature{5}];
         % DailyIntubation
         DailyIntubation = [features(row).DailyIntubation{1}          features(row).DailyIntubation{2}         features(row).DailyIntubation{3}          features(row).DailyIntubation{4}         features(row).DailyIntubation{5}];
         % FiO2
         FiO2 = [features(row).FiO2{1}          features(row).FiO2{2}         features(row).FiO2{3}          features(row).FiO2{4}         features(row).FiO2{5}];
         % PEEP
         PEEP = [features(row).PEEP{1}          features(row).PEEP{2}         features(row).PEEP{3}          features(row).PEEP{4}         features(row).PEEP{5}];
         % Intubated
         Intubated = [features(row).Intubated{1}     features(row).Intubated{2}         features(row).Intubated{3}     features(row).Intubated{4}         features(row).Intubated{5}];
         % UrineOutput
         UrineOutput = [features(row).UrineOutput{1}   features(row).UrineOutput{2}         features(row).UrineOutput{3}   features(row).UrineOutput{4}         features(row).UrineOutput{5}];
         % Dobutamine
         Dobutamine = [features(row).Dobutamine{1}    features(row).Dobutamine{2}         features(row).Dobutamine{3}    features(row).Dobutamine{4}         features(row).Dobutamine{5}];
         % Dopamine
         Dopamine = [features(row).Dopamine{1}      features(row).Dopamine{2}         features(row).Dopamine{3}      features(row).Dopamine{4}         features(row).Dopamine{5}];
         % Epinephrine
         Epinephrine = [features(row).Epinephrine{1}   features(row).Epinephrine{2}         features(row).Epinephrine{3}   features(row).Epinephrine{4}         features(row).Epinephrine{5}];
         % Isoproterenol
         Isoproterenol = [features(row).Isoproterenol{1} features(row).Isoproterenol{2}        features(row).Isoproterenol{3} features(row).Isoproterenol{4}         features(row).Isoproterenol{5}];
         % Milrinone
         Milrinone = [features(row).Milrinone{1}     features(row).Milrinone{2}         features(row).Milrinone{3}     features(row).Milrinone{4}         features(row).Milrinone{5}];
         % Norepinephrine
         Norepinephrine = [features(row).Norepinephrine{1}    features(row).Norepinephrine{2}         features(row).Norepinephrine{3}    features(row).Norepinephrine{4}         features(row).Norepinephrine{5}];
         % Vasopressin
         Vasopressin = [features(row).Vasopressin{1}   features(row).Vasopressin{2}         features(row).Vasopressin{3}   features(row).Vasopressin{4}         features(row).Vasopressin{5}];
         % Other features
         other_features = [features(row).AD features(row).AH features(row).AM features(row).AU features(row).BL features(row).CN features(row).DE features(row).DX features(row).GA features(row).GU features(row).HA features(row).CV100 features(row).CV150 features(row).CV200 features(row).CV250 features(row).CV300 features(row).CV350 features(row).CV400 features(row).CV490 features(row).CV500 features(row).CV600 features(row).CV700 features(row).CV701 features(row).CV702 features(row).CV703 features(row).CV704 features(row).CV709 features(row).CV800 features(row).CV805 features(row).CV806 features(row).CV900 features(row).HS features(row).IR features(row).MS features(row).NT features(row).OP features(row).OR features(row).OT features(row).PH features(row).RE features(row).RS features(row).TN features(row).VT features(row).XX features(row).MedOverlap];
         feature_vector = [Glucose HCT Hgb INR Lactate PLT Potassium Sodium WBC SpO2 Temperature DailyIntubation FiO2 PEEP Intubated UrineOutput Dobutamine Dopamine Epinephrine Isoproterenol Milrinone Norepinephrine Vasopressin other_features];

        data = [data;{id,label,{HRV,ECG,DTCWPT,Art,Spo2},feature_vector}];
    end
    params = containers.Map;
    params('CP ALS Rank') = 3;
    params('HOSVD Modes') = [0,0,2,2,2];
    params('HOSVD Errors') = [0 0 0.1 0.1 0.1];
    params('Non-Tensor-Features') = true;
end
    %{
    %% Split training v. testing dataset
    % Build a map with each DoD ID as the key
    patient_labels = containers.Map('KeyType','double','ValueType','double');
    for i = 1:160
        if isKey(patient_labels, features(i).DoD_ID) == 0
            patient_labels(features(i).DoD_ID) = 0;
        end
    end
    
    % Randomly partition the data for training or testing (DONE BY PATIENT)
    keys = patient_labels.keys;
    for i = 1:length(keys)
        if rand > test_percent
            patient_labels(keys{i}) = 1;
        end
    end

    % Build the training and testing structs
    data = struct2table(features);
    training = table;%(data.Properties.VariableNames);
    % training(:,:) = [];
    testing = table;%
    % testing(:,:) = [];
    for i = 1:length(features)
        % If 1, then that patient is in the training set
        if patient_labels(data{i,1}) == 1
            training = [training; data(i,:)];
        % This patient belongs in the testing dataset
        else
            testing = [testing; data(i,:)];
        end
    end
    %}
