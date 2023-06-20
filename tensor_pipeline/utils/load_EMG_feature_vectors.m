function [feature_vectors, data_path] = load_EMG_feature_vectors(experiment_name)
    %{
    if ispc
        data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\EMG\';
    else
        data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/EMG/';
    end
    %}
    data_path = load_data_path("EMG");
    file_path = char(data_path + experiment_name + "/feature_vectors.mat");
    disp("Loading feature vectors from: " + file_path);
    load(file_path);
end
