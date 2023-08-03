function [loaded_data, params, data_path, filtered]=load_qsofaArt_raw()
    data_path = './';
    
    % sampling rate
    fs = 120;
    
    % Set up parameters
    params = containers.Map;
    params('Sampling F') = fs;
    params('Non-Tensor Features') = false;
    params('Epsilons') = linspace(.1,2.5,5);
    
    file_name = "filteredAbpWithEhr.mat";
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
