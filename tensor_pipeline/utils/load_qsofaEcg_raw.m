function [loaded_data, params, data_path, filtered]=load_qsofaEcg_raw(varargin)
    data_path = './';  % Input your own location here
    
    % sampling rates
    fs = 240;
    
    % Set up parameters
    params = containers.Map;
    params('Sampling F') = fs;
    params('Non-Tensor Features') = true;
    params('Epsilons') = linspace(.01,0.6,5);
    
    if ~isempty(varargin)
        ecgIn = varargin{1};
    else
        file_name = "filteredEcgWithEhr.mat";
        filtered = true;

        file_path = data_path + file_name;
        ecgIn = load(file_path);
        fields = fieldnames(ecgIn);
    end
    
    loaded_data = ecgIn.(fields{1});
    loaded_data.Properties.VariableNames = {'ID', 'EncID' 'Label', 'Signals', 'EHR'};
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
