function [loaded_data, params, data_path, filtered]=load_qsofaArt_raw()
    if ispc
        data_path = 'Z:/Projects/Tensor_Sepsis/Data/Processed/Non-Specific/Modeling/qSOFA/';
    else
        data_path = '/nfs/turbo/med-kayvan-lab/Projects/Tensor_Sepsis/Data/Processed/Non-Specific/Modeling/qSOFA/';
    end
    
    % sampling rate
    fsHrv = NaN;
    
    % Set up parameters
    params = containers.Map;
    params('Sampling F') = fsHrv;
    params('Max Epsilon') = 2;
    params('Non-Tensor Features') = false;
    params('DOD_Epsilon') = linspace(0.001, 0.1, 5);
    
    file_name = "hrvTable.mat";
    filtered = true;

    file_path = data_path + file_name;
    hrvIn = load(file_path);
    fields = fieldnames(hrvIn);
    
    loaded_data = hrvIn.(fields{1});
    loaded_data.Properties.VariableNames = {'ID', 'EncID', 'Label', 'Signals'};
    % Reformat into cell
    for r=1:height(loaded_data)
        sig = loaded_data.Signals{r};
        c = cell(1,1);
        for lead=1:1
            c{lead} = sig;
        end
        loaded_data.Signals{r} = c;
    end
    
end
