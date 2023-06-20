% DESCRIPTION: This function handles loading all tensors and their
% parameters for the tensor decomposition driver script.
%
% Joshua Pickard
% 2/14/2022
%
function [feature_vectors, data_path]=load_feature_vectors(dataset, experiment_name)
    if strcmp(dataset, "CWR")
        [feature_vectors, data_path] = load_CWR_feature_vectors(experiment_name);
    elseif strcmp(dataset, "EMG")
        [feature_vectors, data_path] = load_EMG_feature_vectors(experiment_name);
    elseif strcmp(dataset, "PTB")
        [feature_vectors, data_path] = load_PTB_feature_vectors(experiment_name);
    end
end


