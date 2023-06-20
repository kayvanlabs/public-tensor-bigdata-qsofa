%% Function to load in the Tensor Sepsis Data
%
%  Parameters: healthy and unhealthy cells each containing tensor data, or
%  at least data meant to be transformed into a tensor
%
%  Returns: tables for training and testing
function [data, params] = load_tensor_sepsis(healthyCell, healthyIndices, unhealthyCell, unhealthyIndices)
    data = table([],[],[],[],'VariableNames',{'Ids','Labels','Tensors','Non-Tensor-Features'});
    for i=1:length(healthyCell)
        id = healthyIndices{i};
        tensor = healthyCell{i};
        for j=1:length(id)
            id_sub = id{j};
            tensor_sub = tensor(:,:,:,j);
            id_array = split(id_sub,'/');
            patient_id = string(id_array(2));
            data = [data;{patient_id,0,tensor_sub,[]}];
        end
    end
    for i=1:length(unhealthyCell)
        id = unhealthyIndices{i};
        tensor = unhealthyCell{i};
        for j=1:length(id)
            id_sub = id{j};
            tensor_sub = tensor(:,:,:,j);
            id_array = split(id_sub,'/');
            patient_id = string(id_array(2));
            data = [data;{patient_id,1,tensor_sub,[]}];
        end
    end
    params = containers.Map;
    params('CP ALS Rank') = 5;
    params('HOSVD Modes') = [2];
    params('HOSVD Errors') = [0.1];
    params('Non-Tensor-Features') = false;
end