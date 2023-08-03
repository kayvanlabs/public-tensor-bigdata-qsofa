function [tensors, params, data_path] = load_qsofaEcg_tensors(experiment_name, doHOSVD)
    data_path = load_data_path("qsofaEcg");
    disp("Data path:")
    file_path = char(data_path + experiment_name + "/tensors.mat");
    disp(file_path);
    load(file_path);
    disp("Data loaded");
    
    params = containers.Map;
    %params('Ranks') = [1:9 10:10:100];
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
    return
end