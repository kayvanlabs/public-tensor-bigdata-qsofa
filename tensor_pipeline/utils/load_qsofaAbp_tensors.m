function [tensors, params, data_path] = load_qsofaAbp_tensors(experiment_name, doHOSVD, loadIndices, array_idx)
    data_path = load_data_path("qsofaEcg");
    disp("Data path:")
    file_path = char(data_path + experiment_name + "/tensors.mat");
    disp(file_path);
    
    % Load Art Line tensor
    temp = load(file_path);
    tensors = temp.tensors;
    
    % load indices from ECG
    try
        tempName = strrep(file_path, 'Art_prediction', 'ECG_prediction');
        tempName = regexprep(tempName, '_ECG_Art_.*\/', '_ECG_Art_TS/');
        tempName = strrep(tempName, 'tensors.mat', ['feature_vectors_', num2str(array_idx), '.mat']);
        temp = load(tempName);
    catch ME
        disp(ME.identifier)
    end
    
    disp("Data loaded");
    
    
    params = containers.Map;
    params('Ranks') = [1:10];
    params('CP ALS Rank') = -1; %rank;
    
    if doHOSVD
        params('HOSVD Modes') = [1];
        params('HOSVD Errors') = [0.1001];
    else
        params('HOSVD Modes') = [0];
        params('HOSVD Errors') = [0];
    end
    
    params('Non-Tensor-Features') = true;
    params('Feature Mode') = 4;
    
    if loadIndices
        params('train_ids') = temp.trainIds;
        params('test_ids') = temp.testIds;
        params('folds') = temp.training_idxs;
    end
    
    return
end
