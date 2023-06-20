% DESCRIPTION: This file takes training and testing tensor tables and
% produces a set of corresponding feature vectors by unfolding each tensor
% into a feature vector.
%
% Joshua Pickard jpic@umich.edu, modified by Olivia Pifer Alge

function [train_X,train_y,test_X,test_y,validation_X,validation_y] = vectorize_data(train, test, validation, params)
    [train_X, train_y] = perform_inner_loop(train, params);
    [test_X, test_y] = perform_inner_loop(test, params);
    [validation_X, validation_y] = perform_inner_loop(validation, params);
end

function [x_value, y_value] = perform_inner_loop(dataIn, params)
    x_value = [];
    y_value = dataIn.('Labels');
    for i = 1:height(dataIn)
        feature_vector = reshape(double(dataIn.Tensors{i}), [numel(double(dataIn.Tensors{i})), 1]);
        if params('Non-Tensor-Features')
            iNonTensor = dataIn.('Non-Tensor-Features')(i,:);
             if iscell(iNonTensor) && size(iNonTensor{1}, 2) > 1
                feature_vector = [feature_vector; cell2mat(iNonTensor)'];
             else
                feature_vector = [feature_vector; iNonTensor];
             end
        end
        x_value = [x_value; feature_vector'];
    end
end