%%  cv_split_ids
%   DESCRIPTION: This function returns a set of training indices for each
%                fold based on sample id so that all samples with the same
%                id, which really means generated by the same source data,
%                are in the same fold.
%
%   Author:      Joshua Pickard (jpic@umich.edu)
%   Created:     Aug 2021
%   Modified:    Feb 16 2021

function [training_idxs] = cv_split_ids(data, num_folds)
    % List of all unique patient ids
    unique_ids = unique(data.Ids);
    % make a CV object based on partitioning the IDS
    cv = cvpartition(size(unique_ids,1),'KFold',num_folds);
    % An array to store the training indices based on sample
    training_idxs = [];
    % Loop on each fold
    for fold=1:num_folds
        % Get the ids associated with training
        training_ids_idxs = training(cv, fold)';
        training_ids = unique_ids(training_ids_idxs);
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