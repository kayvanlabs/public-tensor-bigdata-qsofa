% DESCRIPTION: This script compiles the results from different the array
%              job runs of driver_experiments.m
%
%
% data_set = "EMG"; experiment_name = "epsilon_bounds/upper_bounds/1/logspaced"; total_jobs = 45;
% data_set = "CWR"; experiment_name = "epsilons_T_6_75/NOHOSVD"; total_jobs = 30;
% experiments_per_job = [2620 2621]
% ][1180 1181 1179 179 180 181];
function compile_results(data_set, experiment_name, total_jobs, experiments_per_job)
%% SET PARAMETERS
%data_set = "CWR";
%experiment_name = "NOHOSVD_T";
%feature_type = "TS";
%total_jobs = 20;
k_folds = 5;
%% Compile results into 1 struct and save it

% Add paths
if ispc
    addpath(genpath('Z:\Projects\DoD_Multimodal\Code\Joshua\tools\'));
else
    addpath(genpath('/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/tools/'));
end
add_paths();

%[~, ~, data_path] = load_tensors(data_set, "TS");
data_path = load_data_path(data_set);
disp("Data path: " + string(data_path));

compiled_vector_results = table([],[],[],[],[],[],[],[],'VariableNames',{'Number of Windows','Number of Features','Fold','Model','Train Time','Parameters','Predictions','Time'});
compiled_tensor_results = table([],[],[],[],[],[],[],[],[],'VariableNames',{'Number of Windows','Number of Features','Fold','Model','Train Time','Rank','Parameters','Predictions','Time'});


incomplete_jobs = [];
unstarted_jobs = [];

restart_job = [];
for job=1:total_jobs
    file_path = data_path + experiment_name + "/experiment_results_job_" + string(job) + ".mat";
    %file_path = data_path + experiment_name + "/CWR_eps_TS_" + string(job) + "_results.mat";
    disp(file_path);
    if isfile(file_path)
        load(file_path);
        compiled_vector_results = [compiled_vector_results; results.Vector_Results];
        compiled_tensor_results = [compiled_tensor_results; results.Tensor_Results];
        job_num_experiments = height(results.Vector_Results) + height(results.Tensor_Results);
        disp(string(job) + ": " + string(job_num_experiments));
        %{
        if ~any([990 991 992] == job_num_experiments)
            restart_job = [restart_job job];
        end
        %}
        if ~any(experiments_per_job == job_num_experiments)
            incomplete_jobs = [incomplete_jobs job];
            disp(string(job_num_experiments));
            disp('    Incomplete')
        else
            disp(string(job_num_experiments));
            disp('    Complete');
        end
        
    else
        disp('    Unstarted');
        disp(job);
        unstarted_jobs = [unstarted_jobs job];
    end
end

disp(restart_job)

%%
o = "";
for r=restart_job
    o = o + r + ",";
end
disp(o)

%%
disp('Incomplete Jobs: ')
disp(incomplete_jobs)

%normr

disp('Unstarted Jobs: ')
disp(unstarted_jobs)

% Save labels too. Get them from the feature vectors
labels = table([],[],'VariableNames',{'Fold','Labels'});
file_path = data_path + experiment_name + "/feature_vectors_2.mat";
disp("File to get labels")
disp(file_path);
load(file_path) % load feature_vector table
for fold=1:k_folds
    fold_fv = feature_vectors(feature_vectors.Fold == fold,:);
    labels = [labels; {fold, fold_fv.Validation_Y{1}}];
end

%% Save the predictions and labels to a file

results.Tensor_Results = compiled_tensor_results;
results.Vector_Results = compiled_vector_results;
results.True_Labels = labels;
results_path = data_path + experiment_name + "/experiment_complete_results.mat";
save(char(results_path), 'results', '-v7.3');

disp('Job Complete');

end












