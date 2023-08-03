function [loaded_data, params, data_path, filtered]=load_data_raw(data_set)
    if strcmpi(data_set, "qsofaEcg")
        [loaded_data, params, data_path, filtered] = load_qsofaEcg_raw();
    elseif strcmpi(data_set, "qsofaArt")
        [loaded_data, params, data_path, filtered] = load_qsofaArt_raw();
    else
        disp("ERROR: Dataset doesn't exist")
    end
end