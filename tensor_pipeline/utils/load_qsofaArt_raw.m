function [loaded_data, params, data_path, filtered]=load_qsofaArt_raw()
    if ispc
        data_path = 'Z:/Projects/Tensor_Sepsis/Data/Processed/Non-Specific/Modeling/qSOFA/';
    else
        data_path = '/nfs/turbo/med-kayvan-lab/Projects/Tensor_Sepsis/Data/Processed/Non-Specific/Modeling/qSOFA/';
    end
    
    % sampling rate
    fsArt = 120;
    
    % Set up parameters
    params = containers.Map;
    params('Max F') = 100 / 60;  % Find this later
    params('Min F') = 60 / 60;
    params('Sampling F') = fsArt;
    params('Max Epsilon') = 2;
    params('Non-Tensor Features') = false;
    params('DOD_Epsilon') = linspace(.1,2.5,5);
    
    file_name = "filteredAbpTableWithEhr.mat";
    filtered = true;

    file_path = data_path + file_name;
    artIn = load(file_path);
    fields = fieldnames(artIn);
    
    loaded_data = artIn.(fields{1});
    loaded_data.Properties.VariableNames = {'ID', 'EncID', 'Label', 'Signals', 'EHR'};
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
