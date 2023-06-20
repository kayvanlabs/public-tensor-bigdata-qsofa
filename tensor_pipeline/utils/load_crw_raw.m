function [loaded_data, params, data_path, filtered]=load_crw_raw()
    if ispc
        data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\CWR\raw\';
    else
        data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/CWR/raw/';
    end
    loaded_data = table([],[],[],[],'VariableNames',{'ID','Label','Signals','Non-Tensor Features'});    
    % These calculations can be found in data_set_exploration.m
    params = containers.Map;
    params('Max F') = 30;
    params('Min F') = 28.333;
    params('Sampling F') = 48000;
    params('Max Epsilon') = 10;
    params('Non-Tensor Features') = false;
    if isfile(data_path + "filtered_signals.mat") && 0 == 1
        load(data_path + "filtered_signals.mat");
        loaded_data = data_bandpass;
        filtered = true;
    else
        filtered = false;
        baseline_path = "baseline/N_";
        for hp=0:3
            file_path = data_path + baseline_path + string(hp) + ".mat";
            S = load(file_path);
            field_names = fieldnames(S);
            loaded_data = [loaded_data;{height(loaded_data), "N", {}, [hp]}];
            signals = cell(2,1);
            for field_num=1:length(field_names)
                field = field_names{field_num};
                field_pieces = strsplit(field,'_');
                if any(strcmp(strsplit(field, '_'), 'DE'))
                    signals(1) = {S.(field)'};
                    %loaded_data.('DE')(height(loaded_data)) = {S.(field)};
                elseif any(strcmp(strsplit(field, '_'), 'FE'))
                    signals(2) = {S.(field)'};
                    %loaded_data.('FE')(height(loaded_data)) = {S.(field)};
                %elseif any(strcmp(strsplit(field, '_'), 'BA'))
                    %loaded_data.('BA')(height(loaded_data)) = {S.(field)};
                end
            end
            loaded_data.('Signals')(height(loaded_data)) = {signals};
        end

        k48_path = "48k/";
        for letter=["B", "I", "OC"]
            for diameter=[7,14,21]
                for hp=0:3
                    file_path = data_path + k48_path + letter + string(diameter) + "_" + string(hp) + ".mat";
                    S = load(file_path);
                    field_names = fieldnames(S);
                    signals = cell(2,1);
                    for field_num=1:length(field_names)
                        field = field_names{field_num};
                        field_pieces = strsplit(field,'_');
                        if any(strcmp(strsplit(field, '_'), 'DE'))
                            signals(1) = {S.(field)'};
                        elseif any(strcmp(strsplit(field, '_'), 'FE'))
                            signals(2) = {S.(field)'};
                        end
                    end
                    if ~isempty(signals{2})
                        loaded_data = [loaded_data;{height(loaded_data), letter, {signals}, [hp]}];                
                    end
                end
            end
        end
    end
end
