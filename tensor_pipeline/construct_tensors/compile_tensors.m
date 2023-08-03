%   DESCRIPTION: compiles the output from an array job call of driver_tensor.m
%   into one file and saves them in a dictionary where the key is the
%   number of windows in the tensor and the values are that set of tensors.
%   You may need to manually rest the number of windows, i on line 24, that
%   are being compiled.
%   
%   Joshua Pickard (jpic@umich.edu)
%   2/13/2020
%
% data_set = "EMG"; experiment_name = "epsilon_bounds\upper_bounds\1\logspaced";
function compile_tensors(data_set, experiment_name) %f_type)
    %add_paths();
    
    %disp('added paths')
    data_path = load_data_path(data_set);
    % Compile TS tensors
    tensors_TS = containers.Map();
    for i=2:10
        disp(string(i));
        if isfile(char(data_path + experiment_name + "/tensors_" + string(i) + ".mat"))
            load(char(data_path + experiment_name + "/tensors_" + string(i) + ".mat"));
            % Reduce to the selected data
            %if strcmp(data_set, "EMG") % Hardcoded for one of Joshua's data sets
            %    tensors = reduce_data(tensors);
            %    disp("Data Reduction Complete to 1080 samples")
            %end
            tensors_TS(string(i)) = tensors;
        else
            disp('Missing: ' + string(i));
        end
    end
    tensors = tensors_TS;

    %% Save the finished tensors
    save(char(data_path + experiment_name + "/tensors.mat"), 'tensors', '-v7.3');
end
