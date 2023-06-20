%%  build_feature_vectors
%   
%   DESCRIPTION: this function takes the results from the tensor
%   decomposition on the training set as well as a data table and returns
%   an array of feature vectors and their labels.
%
%   PARAMETERS:
%   1. data: a data table similar to those from load_... files
%   2. hosvd_results: a cell array with the results from the hosvd
%   decompositions preformed in tensor_decomposition()
%   3. cp_results: the output of cp_als() which is called in
%   tensor_decomposition()
%   4. params: a dictionary of parameters specific to each dataset. The 
%   only one of importance in this file is 'Non-Tensor-Features' which is a
%   bool representing if there are additional features to be included that
%   are not a part of the tensors
%
%   RETURNS:
%   1. feature_vectors: the feature vectors built using the data table and
%   other parameters
%   2. the labels corresponding to the feature vectors
%
%   Author:  Joshua Pickard jpic@umich.edu
%   Created: Aug 2021

function [feature_vectors, labels] = build_feature_vectors(data, hosvd_results, cp_results, params)
    data_size = size(data);
    num_tensors = size(data.Tensors);
    feature_vectors = [];
    feature_mode = params('Feature Mode');
    for i = 1:data_size(1)
        % Work with 1 row (patient) of the table at a time
        % patient = data(i,:);
        feature_vector = [];

        % Stack the patients tensors
        % Extract each of the 5 tensors
        tensors = {};

        for j=1:num_tensors(2)
            if strcmp(class(hosvd_results{j}),'double')
                tensors{end+1} = data.Tensors{i,j};
            else
                mat = hosvd_results{j};
                t = tensor(data.Tensors{i,j});
                tensors{end+1} = ttm(t, transpose(mat.U{2}), 2);
            end
        end
        patient_tensor = concatenate_tensors(tensors, feature_mode); %tensor(data.Tensors{1});

        
        % Solve equation 10 in the paper
        % Multiply patient tensor by matrices from CP decomposition and solve least squares problem
        
        % Flatten test tensor
        X = tenmat(patient_tensor, feature_mode);
        X = X.data';
        
        % CP ALS Results
        start = 1;
        if feature_mode == 1
            start = 2;
        end
        prod = cp_results.U{start};
        for j=(start+1):(length(cp_results.U)-1)
            if j ~= feature_mode
                prod = khatrirao(prod, cp_results.U{j});
            end
        end
        prod = khatrirao(cp_results.lambda', prod);
        
        B = X\prod;
        feature_vector = (B(:))';
        
        %% Add the rest of the fields to the feature vector
        if params('Non-Tensor-Features')
            iNonTensor = data.('Non-Tensor-Features')(i,:);
            if iscell(iNonTensor) && size(iNonTensor{1}, 2) > 1
                feature_vector = [feature_vector, cell2mat(iNonTensor)];
            else
                feature_vector = [feature_vector, iNonTensor];
            end
        end
        %% Save patients feature vector
        feature_vectors = [feature_vectors; feature_vector];
    end
    labels = data.('Labels');
    feature_vectors = double(feature_vectors);
end 


