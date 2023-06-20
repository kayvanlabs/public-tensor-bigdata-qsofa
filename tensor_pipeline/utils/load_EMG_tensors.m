function [tensors, params, data_path] = load_EMG_tensors(experiment_name)
    %{
    if ispc
        data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\EMG\raw\';
    else
        data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/EMG/raw/';
    end
    %}
    data_path = load_data_path("EMG");
    disp("Data path:")
    file_path = char(data_path + experiment_name + "/tensors.mat");
    disp(file_path);
    load(file_path);
    disp("Data loaded");
    
    params = containers.Map;
    params('Ranks') = [1:9 10:10:100];
    params('CP ALS Rank') = -1; % Do not change
    params('HOSVD Modes') = [0]; % 0 0 0];
    params('HOSVD Errors') = [0]; % 0 0 0];
    params('Non-Tensor-Features') = false;
    params('Feature Mode') = 4;
    return
end
