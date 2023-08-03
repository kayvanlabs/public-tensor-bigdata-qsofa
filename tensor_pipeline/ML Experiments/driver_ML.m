% Sample input: 
%{
    script_ML.sh
    data_set = "CWR"; experiment_name = "NOHOSVD_T"; array_index=1;
    total_jobs=5; previous_jobs = 60;% Computed automatically
%}

function driver_ML(data_set, experiment_name, array_index, total_jobs, previous_jobs)

% Description of experiments being run
description = strvcat({...
    '                              PIPELINE-2'...
    '######################################################################'...
    'Created by: Joshua Pickard'...
    'Date: 2/14/2022'...
    ' '...
    'This driver runs the ML experiments for the tensor project and is set '...
    'up to run on Great Lakes. It accepts 5 parameters, printed below, that'...
    'specify which feature vectors to load and how to split the jobs. The '...
    'models & parameters need to be set from in the script.'...
    '######################################################################'...
    ' '...
    });
disp(description);

% Add paths
if ispc
    addpath(genpath('Z:\Projects\DoD_Multimodal\Code\Joshua\DOD\matlab\utils\'));
else
    addpath(genpath('/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/DOD/matlab/utils/'));
end
add_paths();

data_path = load_data_path(data_set);
%{
if 0==1%~ispc || nargin < 3
    disp("Not enough parameters");
    disp("driver_ML(data_set, experiment_name, array_index, total_jobs, previous_jobs)");
elseif nargin == 4
    disp("Checking if pervious jobs have been run")
    previous_jobs = 0;
    while isfile(char(data_path + experiment_name + "/experiment_results_job_" + string(array_index + previous_jobs) + ".mat"))
        file_info = dir(char(data_path + experiment_name + "/experiment_results_job_" + string(array_index + previous_jobs) + ".mat"));
        file_info.date
        previous_jobs = previous_jobs + 1;
    end
    disp("Previous Jobs to run on this data: " + string(previous_jobs));
else
    disp("Passed as a parameter, previous jobs: " + string(previous_jobs));
end
%}
disp("BASH Passed PARAMETERS")
disp("    data set:      " + data_set);
disp("    experiment:    " + experiment_name);
disp("    array index:   " + string(array_index));
disp("    total jobs:    " + string(total_jobs));
disp("    previous jobs: " + string(previous_jobs));
disp(" ");

% Load data
[feature_vectors, ~] = load_feature_vectors(data_set, experiment_name);
%experiment_name = experiment_name + "_NBC";
disp("    experiment:   " + experiment_name);
save_path = data_path + experiment_name + "/experiment_results_job_" + string(array_index + previous_jobs) + ".mat"; %"CWR_DTCWPT_" + string(array_index) + ".mat";
%save_path = data_path + file_name;
disp("Results saved to: ")
disp("    " + save_path);
disp(" ");
disp("Feature vectors loaded")
disp("    Total feature-vector sets: " + string(height(feature_vectors)));
disp(" ");

% Set model Parameters
models_and_parameters = table([],[],'VariableNames',{'Model','Hyperparameters'});
%{
% LUCCK Parameters
for theta_i=-2:1%-5:1
    theta = 10^(2*theta_i);
    for lambda_i=-4:1%-9:1
        lambda = 10^(2*lambda_i);
        models_and_parameters = [models_and_parameters; {'LUCCK', {[lambda theta]}}];
    end
end
%}
% Neural Network
% models_and_parameters = [models_and_parameters; {'NN', {[0]}}];
% Naive Bayes

models_and_parameters = [models_and_parameters; {'NBC', {[0]}}];
% SVM Parameters
for gamma_exp=-6:6%-12:13
    gamma = 10^(2*gamma_exp);
    for box_constraint_exp=-3:6%-6:13
        box_constraint = 10^(2*box_constraint_exp);
        %if strcmp(kernel, "rbf")
            models_and_parameters = [models_and_parameters; {'SVM', {[{'rbf'} {gamma box_constraint}]}}];
        %elseif strcmp(kernel, "poly")
        %    models_and_parameters = [models_and_parameters; {'SVM', {[{'polynomial'} {gamma box_constraint}]}}];
        %end
    end
end


% TreeBagger Parameters"compile_tensors
%{
num_leafs = [1 5 10 15 20];
num_trees = [50 75 100];
for trees_i=1:length(num_trees)
    trees = num_trees(trees_i);
    for leaf=num_leafs
        models_and_parameters = [models_and_parameters; {'TreeBagger', {[trees leaf]}}];
    end
end
%}
disp('Model Parameters Set');
disp("    Total models: " + string(height(models_and_parameters)));
disp(" ");

% Set structs to save results in
vector_results = table([],[],[],[],[],[],[],[],'VariableNames',{'Number of Windows','Number of Features','Fold','Model','Train Time','Parameters','Predictions','Time'});
tensor_results = table([],[],[],[],[],[],[],[],[],'VariableNames',{'Number of Windows','Number of Features','Fold','Model','Train Time','Rank','Parameters','Predictions','Time'});

% Set data_model_pairs (broadcast variable)
[A,B] = meshgrid(1:height(models_and_parameters),1:height(feature_vectors));
c=cat(2,A',B');
data_model_pairs=reshape(c,[],2);

% Set this part based on job array index
%for array_index = 1:total_jobs
num_experiments_per_job = floor(length(data_model_pairs) / total_jobs);
low = max(num_experiments_per_job * (array_index - 1),1);
high = num_experiments_per_job * (array_index);
num_experiments = length(data_model_pairs);
if array_index ~= total_jobs
    data_model_pairs = data_model_pairs(low:high,:);
else
    data_model_pairs = data_model_pairs(low:end,:);
end
disp("A total of " + string(num_experiments)+ " experiments need to be run.");
disp("This job, array job " + string(array_index) + ", is running experiments " + string(low) + " through " + string(high) + ".");
%end

experiments_run = high - low;

%% Check if the experiment is being restarted
skipped = 0;
section = 0;
section_size = 500; % DO NOT CHANGE THIS
if isfile(save_path)
    disp("This experiment is being restarted from an earlier job.")
    load(save_path);
    vector_results = results.Vector_Results;
    tensor_results = results.Tensor_Results;
    disp("Previous data is being loaded in from: " + string(save_path));
    section = height(vector_results) + height(tensor_results); % / section_size;
    disp("Restarting on section: " + string(section));
else
    disp("A template of the results has been saved to a file.")
    results = struct('Vector_Results', vector_results, 'Tensor_Results', tensor_results);
    save(save_path, 'results'); 
    disp("Results are saved at:");
    disp(save_path);
end

%% Loop to save experiments sporatically
while section < length(data_model_pairs)
    % Each section runs its experiments in parallel
    %ticBytes(gcp);
    %ticBytes(gcp);
    parfor experiment_par=1:section_size
        experiment = section + experiment_par;
        if experiment > length(data_model_pairs)
            continue
        end
        %% Set these inside parfor loop
        train_time = 0;
        predictions = 0;
        disp("    experiment:" + string(experiment) + "/" + string(length(data_model_pairs)));
        % Select the data and model for a given experiment
        row = data_model_pairs(experiment,:);
        model_row = row(1);
        data_row = row(2);
        experiment_data = feature_vectors(data_row,:);
        % Remove any imaginary component if one exist
        experiment_data.Training_X{1} = real(experiment_data.Training_X{1});
        experiment_data.Validation_X{1} = real(experiment_data.Validation_X{1});
        %disp(unique(experiment_data.Training_Y{1}));
        %if length(unique(experiment_data.Training_Y{1})) == 1
        %    continue;
        %end
        
        model_parameters = models_and_parameters(model_row,:);
        params = model_parameters.Hyperparameters{1};
        %%
        if strcmp(model_parameters.Model{1}, 'SVM')
            t = templateSVM('KernelFunction',params{1},'KernelScale',params{2},'BoxConstraint',params{3});
            tic;
            model = fitcecoc(experiment_data.Training_X{1}, experiment_data.Training_Y{1},'Learners',t);
            train_time = toc;
            predictions = predict(model, experiment_data.Validation_X{1});
        elseif strcmp(model_parameters.Model{1}, 'NBC')
            % Technically this also times the predictions, not just the
            % training
            tic;
            predictions = train_NB(experiment_data.Training_X{1}, experiment_data.Training_Y{1}, experiment_data.Validation_X{1});
            train_time = toc;
        elseif strcmp(model_parameters.Model{1}, 'NN')
            disp('    NN experiment');
            continue;
            %net = patternnet(10);
            net = feedforwardnet(10);
            % Convert labels to OHEs
            offset = false;
            if min(experiment_data.Training_Y{1}') == 0
                offset = true;
                experiment_data.Training_Y{1} = experiment_data.Training_Y{1} + 1;
            end
            % one_hot_labels = ind2vec(experiment_data.Training_Y{1}');
            % x = categorical(experiment_data.Training_Y{1});
            % experiment_data.Training_Y{1};
            disp("OHE");
            one_hot_labels = bsxfun(@eq, experiment_data.Training_Y{1}(:), 1:max(experiment_data.Training_Y{1}));
            
            %one_hot_labels = onehotencode(x, 2); %sort(unique(experiment_data.Training_Y{1}')));
            %num2str(x)
            %xx = num2str(experiment_data.Training_Y{1})
            %xx = char(xx)
            net.trainParam.showWindow = 0;
            net.trainParam.epochs=200;
            disp("start train");
            try
                disp(size(experiment_data.Training_X{1}));
                tic;
                net = train(net, experiment_data.Training_X{1}', one_hot_labels');
                toc;
            catch
                disp("failed");
                disp(size(experiment_data.Training_X{1}));
            end
            network_output = net(experiment_data.Validation_X{1}');
            [~,predictions] = max(network_output);
            predictions = predictions';
            if offset
                predictions = predictions - 1;
            end
            %predictions = train_NB(experiment_data.Training_X{1}, experiment_data.Training_Y{1}, experiment_data.Validation_X{1});
            %train_time = toc;
        elseif strcmp(model_parameters.Model{1}, 'TreeBagger')
            tic;
            model = TreeBagger(params(1), experiment_data.Training_X{1}, experiment_data.Training_Y{1}, 'MinLeafSize', params(2));
            train_time = toc;
            predictions = predict(model, experiment_data.Validation_X{1});
        elseif strcmp(model_parameters.Model{1}, 'LUCCK')
            lucck_labels = mat2cell(num2str(experiment_data.Training_Y{1}), ones(length(experiment_data.Training_Y{1}),1));
            tic;
            [~, predictions_char] = myML3(experiment_data.Training_X{1}, lucck_labels, num2str(unique(experiment_data.Training_Y{1})), experiment_data.Validation_X{1}, params(1), params(2), ones(height(experiment_data.Training_X{1}),1));
            train_time = toc;
            predictions = str2num(predictions_char);        
        end
        % Save the results
        if strcmp(experiment_data.Decomp{1},'Tensor')
            tensor_results = [tensor_results; {experiment_data.Num_Windows(1), width(experiment_data.Training_X{1}), experiment_data.Fold(1), model_parameters.Model{1}, train_time, experiment_data.Rank(1), model_parameters, predictions, train_time}];
        elseif strcmp(experiment_data.Decomp{1},'Vector')
            vector_results = [vector_results; {experiment_data.Num_Windows(1), width(experiment_data.Training_X{1}), experiment_data.Fold(1), model_parameters.Model{1}, train_time, model_parameters, predictions, train_time}];
        end
    end
    %tocBytes(gcp);
    section = section + section_size;
    disp("Saving current results. to file. A total of " + string(section) + " out of " + length(data_model_pairs) + ...
        " experiments have run to completion");
    results = struct('Vector_Results', vector_results, 'Tensor_Results', tensor_results);
    save(save_path, 'results');
    disp("Results are saved at:");
    disp(save_path);
end
disp("All experiments have run to comletion, and the results are being saved.")
results = struct('Vector_Results', vector_results, 'Tensor_Results', tensor_results);
save(save_path, 'results'); 
disp("Results are saved at:");
disp(save_path);

disp('Experiments Supposed to Run:');
disp(experiments_run);
disp('Experiments Skipped:');
disp(skipped);

disp("Job Complete")

%% PARFOR test
%{
disp(nws)
ticBytes(gcp);
parfor i=1:1000
    disp(i)
end
tocBytes(gcp);
%}
end
