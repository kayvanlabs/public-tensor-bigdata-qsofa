%% train_NB
%
%  DESCRIPTION: This function builds and trains a naive bayes classifier
%  using fitcnb. This function is needed when there is no variance within a
%  feature in a given class. It works with the following steps:
%   1. For each class, identify the features with 0 variance
%   2. Add gaussian noise to these features
%   3. call fitcnb to train the model
%   4. Specify in the prdictor probabilities the mean of the distribution
%   and 0 variance
%
% X_train = experiment_data.Training_X{1};
% Y_train = experiment_data.Training_Y{1};
% X_val = experiment_data.Validation_X{1};
function predictions = train_NB(X_train, Y_train, X_val)
    [~, num_features] = size(X_train);
    classes = unique(Y_train);
    zero_variance_distributions = zeros(length(classes), num_features); %cell(length(classes), num_features);
    class_small = 0;
    if min(classes) == 0
        class_small = 1;
    end
    % Identify features with 0 variance
    for class_i=1:length(classes)
        class = classes(class_i);
        class_samples = X_train(Y_train == class, :);
        for n=1:num_features
            if length(unique(class_samples(:,n))) == 1
                zero_variance_distributions(class + class_small,n) = 1; %class_samples(1,n);
            end
        end
    end
    
    % Add in gaussian noise to these features
    for class_i=1:length(classes)
        class = classes(class_i);
        class_samples = X_train(Y_train == class, :);
        for n=1:num_features
            % Add wnoise to the 0-var features
            if zero_variance_distributions(class + class_small,n)
                class_samples(1, n) = class_samples(1, n) + 1e-100;
                class_samples(2, n) = class_samples(2, n) - 1e-100;
            end
        end
        X_train(Y_train == class, :) = class_samples;
    end
    
    % Train model using all features
    general_model = fitcnb(X_train, Y_train);

    % Identify classes with 0 variance features
    bad_classes = [];
    for class_i=1:length(classes)
        class = classes(class_i);
        if sum(zero_variance_distributions(class + class_small,:)) ~= 0
            bad_classes = [bad_classes class];
        end
    end

    % Train individual class models
    specific_class_models = cell(length(classes), 1);
    for class_i=1:length(classes)
        class = classes(class_i);
        if any(bad_classes(:) == class)
            % Train a model for this class
            % Select which features to include
            class_features = ~logical(zero_variance_distributions(class + class_small, :));
            % sum(class_features);
            X_train_class = X_train(:, class_features);
            class_model = fitcnb(X_train_class, Y_train);
            specific_class_models{class + class_small} = class_model;
        end
    end
    
    %% Make predictions
    
    general_labels = predict(general_model, X_val);
    specific_class_model_labels = cell(length(classes), 1);
    for class_i=1:length(classes)
        class = classes(class_i);
        if any(bad_classes(:) == class)
            % Train a model for this class
            % Select which features to include
            class_features = ~logical(zero_variance_distributions(class + class_small, :));
            X_val_class = X_val(:, class_features);
            class_model = specific_class_models{class + class_small};
            specific_class_model_labels{class + class_small} = predict(class_model, X_val_class);
        end
    end
    
    %% Check if predictions are the same for all models
    % assume general predictions are true but check each individual class
    % predictor as well. If a class predictor predicts itself, then it is
    % assumed to be correct instead of the general one. This will tally the
    % number of conflicts between the class predictors and the general one
    % as well
    different_predictions = 0;
    [num_predictions, ~] = size(X_val);
    for sample=1:num_predictions
        for class_i = 1:length(classes)
            class = classes(class_i);
            if ~isempty(specific_class_model_labels{class + class_small})
                if specific_class_model_labels{class + class_small}(sample) == class
                    if specific_class_model_labels{class + class_small}(sample) ~= general_labels(sample)
                        different_predictions = different_predictions + 1;
                    end
                    general_labels(sample) = class;
                end
            end
        end
    end
    
    disp(string(different_predictions) + "/" + string(num_predictions));
    
    predictions = general_labels;
end

% ClassificationNaiveBayes

%{

    posterior_probabilities = zeros(length(X_val), length(classes));
    [~, general_posteriors, ~] = predict(general_model, X_val);
        
    X_val_class = X_val(:, class_features);
    [~, posteriors, ~] = predict(individual_class_models{1}, X_val_class)


    %[idxs_2,idxs] = intersect(bad_classes,Y_train,'stable')
    [bad_idxs, ~] = ismember(Y_train, bad_classes);
    good_idxs = ~bad_idxs;

    % Fit model to classes that use all features
    Y_train_temp = Y_train(good_idxs);
    X_train_temp = X_train(good_idxs, :);
    general_model = fitcnb(X_train_temp, Y_train_temp);

    
    % Add in gaussian noise to these features
    for class_i=1:length(classes)
        class = classes(class_i);
        class_samples = X_train(Y_train == class, :);
        for n=1:num_features
            % Add wnoise to the 0-var features
            if ~isempty(zero_variance_distributions{class + class_small,n})
                class_samples(1, n) = class_samples(1, n) + 1e-100;
                class_samples(2, n) = class_samples(2, n) - 1e-100;
            end
        end
        X_train(Y_train == class, :) = class_samples;
    end
    % Train the classifier
    model = fitcnb(X_train_temp, Y_train_temp);
    % Reset the predictor distributions
    % The comminted out code doesn't currently work because certain
    % properties of the model class are read only.jjjjjj
    %{
    for class_i=1:length(classes)
        class = classes(class_i);
        class_samples = X_train(Y_train == class, :);
        for n=1:num_features
            % Add wnoise to the 0-var features
            if ~isempty(zero_variance_distributions{class + class_small,n})
                model.DistributionParameters{class + class_small, n} = [zero_variance_distributions{class + class_small,n} 0];
                disp(model.DistributionParameters{class + class_small, n})
            end
        end
    end
    %}


X_t = experiment_data.Training_X{1};
Y_t = experiment_data.Training_Y{1};
X_0 = X_t(Y_t == 0,:);
X_1 = X_t(Y_t == 1,:);
X_2 = X_t(Y_t == 2,:);
X_3 = X_t(Y_t == 3,:);

m1 = fitcnb(X_1, ones(40,1))
m2 = fitcnb(X_2, ones(29,1)*2)

% Combine model 1 and model 2
m = fitcnb([], [], 'ClassNames',[1 2],'Prior',[0.4, 0.6])
%}