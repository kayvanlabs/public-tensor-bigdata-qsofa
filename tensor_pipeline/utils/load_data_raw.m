function [loaded_data, params, data_path, filtered]=load_data_raw(data_set)
    if strcmp(data_set, "PTB")
        [loaded_data, params, data_path, filtered] = load_ptb_raw();
    elseif strcmp(data_set, "EMG")
        [loaded_data, params, data_path, filtered] = load_emg_raw();
    elseif strcmp(data_set, "CWR")
        [loaded_data, params, data_path, filtered] = load_crw_raw();
    elseif strcmp(data_set, "MFPT")
        [loaded_data, params, data_path, filtered] = load_mfpt();
    elseif strcmp(data_set, "Ottawa")
        [loaded_data, params, data_path, filtered] = load_ottawa();
    elseif strcmpi(data_set, "qsofaEcg")
        [loaded_data, params, data_path, filtered] = load_qsofaEcg_raw();
    elseif strcmpi(data_set, "qsofaArt")
        [loaded_data, params, data_path, filtered] = load_qsofaArt_raw();
    elseif strcmpi(data_set, "qsofaHrv")
        [loaded_data, params, data_path, filtered] = load_qsofaHrv_raw();
    else
        disp("ERROR: Dataset doesn't exist")
    end
end