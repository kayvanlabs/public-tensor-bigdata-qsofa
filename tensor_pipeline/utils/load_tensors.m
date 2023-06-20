% DESCRIPTION: This function handles loading all tensors and their
% parameters for the tensor decomposition driver script.
%
% Joshua Pickard
% 2/14/2022
%
function [tensors, params, data_path]=load_tensors(dataset, feature_type, doHOSVD, array_idx)
    if strcmp(dataset, "CWR")
        [tensors, params, data_path] = load_CWR_tensors(feature_type);
    elseif strcmp(dataset, "EMG")
        [tensors, params, data_path] = load_EMG_tensors(feature_type);
    elseif strcmp(dataset, "PTB")
        [tensors, params, data_path] = load_PTB_tensors(feature_type);
    elseif strcmpi(dataset, "qsofaEcg")
        [tensors, params, data_path] = load_qsofaEcg_tensors(feature_type, doHOSVD);
    elseif strcmpi(dataset, "qsofaHrv")
        [tensors, params, data_path] = load_qsofaHrv_tensors(feature_type, doHOSVD, true, array_idx);
    elseif strcmpi(dataset, "qsofaArt")
        [tensors, params, data_path] = load_qsofaAbp_tensors(feature_type, doHOSVD, true, array_idx);
    end
    % Remove "raw/" from each path
    data_path = data_path(1:end-4);
end


