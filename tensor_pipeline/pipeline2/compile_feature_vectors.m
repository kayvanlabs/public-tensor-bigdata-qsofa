%% Compile feature vectors
%
%   DESCRIPTION: This file compiles the ourputs of driver_decomp.m from
%   each job in the array job into one file
%
% Joshua Pickard jpic@umich.edu

function compile_feature_vectors(data_set, experiment_name) %, feature_type)
%data_set = "PTB";
%experiment_name = "NOHOSVD";
%feature_type = "TS_1080";
%% Parameters to set
% data_set = "CWR";
% feature_type = "eps_DTCWPT";
disp("Compiling Feature Vectors");
% Add paths
if ispc
    addpath(genpath('Z:\Projects\DoD_Multimodal\Code\Joshua\DOD\matlab\utils'));
else
    addpath(genpath('/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/DOD/matlab/utils'));
end
add_paths();

data_path = load_data_path(data_set);
disp("Data path: " + string(data_path));

%% Concatenate the results

compile_feature_vectors = table([],[],[],[],[],[],[],[],'VariableNames',{'Num_Windows','Decomp','Fold','Rank','Training_X','Training_Y','Validation_X','Validation_Y'});

%[~, ~, data_path] = load_tensors(data_set, feature_type);
disp("Data path: " + string(data_path));

for nws=2:10
    if isfile(data_path + experiment_name + "/feature_vectors_" + string(nws) + ".mat")
        load(char(data_path + experiment_name + "/feature_vectors_" + string(nws) + ".mat"));
        compile_feature_vectors = [compile_feature_vectors; feature_vectors];
    else
        disp("Window " + string(nws) + " incomplete.")
    end
end

feature_vectors = compile_feature_vectors;
save(char(data_path + experiment_name + "/feature_vectors.mat"), 'feature_vectors','-v7.3');
disp("Feature Vectors Compiled");
end
