%% Function for Generalized Tensor Decomposition and Feature Extraction
%
%  DESCRIPTION: This function is intended to be a generalized method for
%  the tensor decomposition and feature extraction we have discussed in the
%  paper. Specifically, this code deals with a generalized method for the
%  section after tensor formation, 3.6.2 and on.
%
%  PARAMETERS:
%
%   1. tensors: is a vector of the tensors that will be in the algorithm.
%   In the lens of the paper, each element in the vector corresponds to 1
%   of the tensors formed from a type of feature (ECG, SpO2, etc.) for all
%   patients.
%
%   2. HOSVD_errors: is a vector representing the error allowed for the
%   HOSVD decomposition of each tensor in tensors. Note: for all tensors
%   that do NOT undergo HOSVD decompositing, the corresponding error should
%   be 0.
%
%   3. HOSVD_modes: for all tensors that undergo HOSVD decomposition, this
%   vector lists which mode that occurs in. If the tensor doesn't have
%   HOSVD applied to it, by default we leave it as 0
%
%   5. CP_ALS_rank: is the rank used for the CP ALS reduction
%
% Joshua Pickard jpic@umich.edu

function [HOSVD_results, CP_ALS_results] = tensor_decomposition(tensors, params)
    %% Set parameters
    HOSVD_modes = params('HOSVD Modes');
    HOSVD_errors = params('HOSVD Errors');
    CP_ALS_rank = params('CP ALS Rank');
    feature_mode = params('Feature Mode');
    
    %% HOSVD
    HOSVD_results = cell(length(HOSVD_errors), 1);
    for i = 1:length(tensors)
        if HOSVD_errors(i) ~= 0
            % Get size of tensor
            tensor_size = size(tensors{i});
            % Set first search point to 1/2 the size of the searching mode
            upper = tensor_size(HOSVD_modes(i));
            lower = 1;
            tensor_size(HOSVD_modes(i)) = lower + round((upper - lower) / 2 - 0.0001);
            % Recursively search using this funcion
            [T, ~] = hosvd_bin_search(tensors{i}, HOSVD_errors(i), tensor_size, upper + 1, lower, HOSVD_modes(i));
            % Save HOSVD results
            HOSVD_results{i} = T;
        else
            HOSVD_results{i} = 0;
        end
    end
    
    tensors_post_HOSVD = {};
    for i = 1:length(tensors)
        if HOSVD_errors(i) ~= 0
            tensors_post_HOSVD{i} = HOSVD_results{i}.core;
        else
            tensors_post_HOSVD{i} = tensors{i};
        end
    end
    disp("Original size: ");
    disp(size(tensors{1}))
    disp("Post HOSVD size: ");
    disp(size(tensors_post_HOSVD{1}));
    concatenated_tensor = concatenate_tensors(tensors_post_HOSVD, feature_mode);
    
    %% CP ALS Decomposition
    % Multiple trials of CP decomposition are performed and the results
    % with the best fit are used.
    real_norm = norm(concatenated_tensor);
    num_cpals = 15;
    best_score = 0;
    t = 0;
    while t < num_cpals
        reconstruction = cp_als(concatenated_tensor, CP_ALS_rank);
        score = 1 - (norm(concatenated_tensor - reconstruction) / real_norm);
        if score > best_score || t == 0
            best_score = score;
            CP_ALS_results = reconstruction;
        end
        if score == 1
            break;
        end
        t = t + 1;
    end    
end

