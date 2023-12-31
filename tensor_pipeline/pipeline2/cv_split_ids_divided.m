%%  cv_split_ids_divided
%   DESCRIPTION: This function returns a set of training indices for each
%                fold based on sample id so that all samples with the same
%                id, which really means generated by the same source data,
%                are in the same fold. This also tries to keep an even
%                ratio of positive/negative samples across folds
%
%   Author:      Joshua Pickard (jpic@umich.edu), modified by Olivia Pifer
%                Alge
%   Created:     Aug 2021
%   Modified:    Feb 16 2021

function [training_idxs] = cv_split_ids_divided(data, num_folds)
    % List of all unique patient ids
    unique_ids = unique(data(:, ["Ids", "Labels"]));
    
    % assumes pos == 1 and neg == 0
    pos_rows = logical(unique_ids.Labels);
    pos_ids = unique_ids{pos_rows, "Ids"};
    neg_ids = unique_ids{~pos_rows, "Ids"};
    % See if there is overlap between positive and negative
    has_overlap = ismember(unique_ids{pos_rows, "Ids"}, ...
                           unique_ids{~pos_rows, "Ids"});
    if any(has_overlap)
        if sum(unique_ids.Labels) > sum(~unique_ids.Labels)
            pos_ids(has_overlap) = [];
        else
            overlapping_ids = pos_ids(has_overlap);
            neg_ids(ismember(neg_ids, overlapping_ids)) = [];
        end
    end
    
    % make a CV object based on partitioning the IDS
    cv_pos = cvpartition(size(pos_ids,1),'KFold',num_folds);
    cv_neg = cvpartition(size(neg_ids,1),'KFold',num_folds);
    % An array to store the training indices based on sample
    training_idxs = [];
    % Loop on each fold
    for fold=1:num_folds
        % Get the ids associated with training
        training_ids_idxs_pos = training(cv_pos, fold)';
        training_ids_pos = pos_ids(training_ids_idxs_pos);
        training_ids_idxs_neg = training(cv_neg, fold)';
        training_ids_neg = neg_ids(training_ids_idxs_neg);
        
        training_ids = [training_ids_pos; training_ids_neg];
        
        % Make a temp array to store which are for training
        training_fold_idxs = ones(height(data),1);
        % Check each sample
        for i=1:height(data)
            % If a sample doesn't have an id in training_ids, then that
            % sample has a 0 value in the training_fold_idxs
            if ~ismember(data.Ids(i), training_ids)
                training_fold_idxs(i) = 0;
            end
        end
        % append the sample idxs for a fold to a larger array
        training_idxs = [training_idxs; training_fold_idxs'];
    end
    training_idxs = logical(training_idxs);
end