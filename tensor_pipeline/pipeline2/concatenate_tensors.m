%% Concatenate Tensors
%
%  DESCRIPTION: This file takes tensors and concatenates them in the
%  feature mode
%
% Joshua Pickard jpic@umich.edu

function concatenated_tensor = concatenate_tensors(tensors, feature_mode)
    
    tensor_dimensions = [];
    for i=1:length(tensors)
        tensor_dimensions = [tensor_dimensions; size(tensors{i})];
    end
    feature_mode_length = sum(tensor_dimensions(:,feature_mode));
    concatenated_tensor_size = size(tensors{1});
    concatenated_tensor_size(feature_mode) = feature_mode_length;
    concatenated_tensor = tenzeros(concatenated_tensor_size);
    
    place_holder_1 = {};
    for i=1:(feature_mode-1)
        place_holder_1{end+1} = ':';
    end
    place_holder_2 = {};
    for i=1:(length(size(tensors{1}))-feature_mode)
        place_holder_2{end+1} = ':';
    end
    feature_mode_counter = 1;
    for i=1:length(tensors)
        feature_mode_stop = feature_mode_counter+tensor_dimensions(i,feature_mode)-1;
        concatenated_tensor(place_holder_1{:},feature_mode_counter:feature_mode_stop,place_holder_2{:}) = tensors{i};
        feature_mode_counter = feature_mode_stop;
    end
end
