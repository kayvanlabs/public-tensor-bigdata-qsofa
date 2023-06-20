%% tensor_method
%
%   DESCRIPTION: This file takes the train & test data tables from the load
%   file, parameters for HOSVD & CP ALS, preforms the tensor method and
%   returns the feature vectors and labels for both training & testing
%
%   PARAMETERS:
%   - train: a table with similar fields to those from a load_... file with
%   the data to be used for training the method
%   - test: a table with similar fields to those from a load_... file with
%   the testing data
%   - params: a dictionary containing fields important for running the
%   tensor method and building the feature vectors. This comes directly
%   from each data sets load file. Current fields in params:
%       - HOSVD_errors: an array of the error tolerances for each tensor 
%       type that undergoes HOSVD. If the error for a tensor is 0, then 
%       that tensor is skipped for HOSVD
%       - HOSVD_modes: this is the mode that HOSVD will occur in. If the 
%       tensor is being skipped based on HOSVD_errors, then this value is 
%       irrelevant and should be left as '0'
%       - CP_ALS_rank: the rank of the CP ALS approximation
%       - Non-Tensor-Features: a bool used to determine if there are
%       additional features as a part of the dataset that are separate from
%       the tensors
%
%   RETURNS:
%   1. train_X: the feature vectors for the training data
%   2. train_y: the labels for the training data
%   3. test_X: the feature vectors for the testing data
%   4. test_y: the labels for the training data
%
%   Author:  Joshua Pickard jpic@umich.edu
%   Created: Aug 2021

function [train_X,train_y,test_X,test_y,val_x, val_y] = tensor_method(train, test, validation, params)
%% Tensor Analysis
stacked_training_tensors = stack_tensors(train.Tensors);

% perform HOSVD and CP decompositions
[HOSVD_results, CP_ALS_results] = tensor_decomposition(stacked_training_tensors, params);

%% Extract training and testing featues and labels
[train_X, train_y] = build_feature_vectors(train, HOSVD_results, CP_ALS_results, params);
[val_x, val_y] = build_feature_vectors(validation, HOSVD_results, CP_ALS_results, params);
[test_X, test_y] = build_feature_vectors(test, HOSVD_results, CP_ALS_results, params);
end