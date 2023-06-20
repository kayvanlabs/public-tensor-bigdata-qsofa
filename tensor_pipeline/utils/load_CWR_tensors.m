function [tensors, params, data_path] = load_CWR_tensors(experiment_name)
    if ispc
        data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\CWR\';
    else
        data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/CWR/';
    end
    disp("Data path:")
    file_path = char(data_path + experiment_name + "/tensors.mat");
    disp(file_path);
    load(file_path);
    disp("Data loaded");
    % Set all labels to numeric values instead of chars
    for k=tensors.keys
        tbl = tensors(k{1});
        % Reset labels
        for h=1:height(tbl)
            if strcmp(tbl.Labels(h), "N")
                tbl.Labels(h) = 0;
            elseif strcmp(tbl.Labels(h), "B")
                tbl.Labels(h) = 1;
            elseif strcmp(tbl.Labels(h), "I")
                tbl.Labels(h) = 2;
            elseif strcmp(tbl.Labels(h), "OC")
                tbl.Labels(h) = 3;
            end
        end
        tbl.Labels = str2double(tbl.Labels);
        tensors(k{1}) = tbl;
    end
    disp("Labels set to numeric values");
    params = containers.Map;
    % -1 is set to indicate vectorization
    params('Ranks') = [1:9 10:10:100];
    params('CP ALS Rank') = -1;
    params('HOSVD Modes') = [0]; %[4, 4];
    params('HOSVD Errors') = [0]; %[0.1, 0.1];
    params('Non-Tensor-Features') = false; % Experiments are being run as tensor only
    params('Feature Mode') = 4;
    disp("Parameters set");
end


%data.Labels = grp2idx(data.Labels);