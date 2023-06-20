function [feature_vectors, data_path] = load_CWR_feature_vectors(experiment_name)
    data_path = load_data_path("CWR");
    file_path = char(data_path + experiment_name + "/feature_vectors.mat");
    disp("Loading feature vectors from: " + file_path);
    load(file_path);
    
    % Remove all experiments with feature vectors longer than the longest vectorized feature vector
    %{
    % Vectorized feature vectors
    vec = feature_vectors(strcmp(feature_vectors.Decomp, "Vector"),:);
    % Find longest
    max_len = 0;
    for v=1:height(vec)
        s = size(vec.Training_X{v});
        if s(2) > max_len
            max_len = s(2);
        end
    end
    % Find all rows that need to be deleted
    save_rows = ones(height(feature_vectors),1)
    for r=1:height(feature_vectors)
        s = size(feature_vectors.Training_X{r});
        if s(2) > max_len
            save_rows(r) = 0;
        end
    end
    feature_vectors = feature_vectors(logical(save_rows),:);
    %}
end
