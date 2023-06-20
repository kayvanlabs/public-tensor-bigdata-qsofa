%   DESCRIPTION: This is the driver file for this directory. It is the only
%   command that needs to be called to run the job on GreatLakes, and it is
%   called in script_tensorize.sh, which is intented to be run as an array
%   job, where the array index is the number of windows in the tensors.
%   
%   This function accepts a dataset, experiment_name, feature type, and 
%   num_windows which are used as parameters to construct tensors. The
%   raw data will be loaded and turned into tensors of the size:
%
%       <num signals> x <num windows> x <num epsilons> x <num features>
%
%   The dataset must have specific loader functions for it, and the tensors
%   will be saved in the experiment_name subdirectory. The epsilons must be
%   set manually at this point, and the TS_epsilons function should not
%   currently be used. These tensors can be constructed with either Taut
%   String 'TS' or Wavelet Features 'DTCWPT'
%
%   The primary tensor construction occurs within the construct_tensors.m
%   file.
%
%   The following file structure is used to manage these experiments, and
%   as you add new datasets or run new experiments, you should add updated
%   functions to the ../utils/ directory. Each dataset D has its own
%   directory. In it is a raw/ subdirectoy, containing the raw data signals
%   for each sample in a table, these are loaded into this function with
%   the load_data_raw(data_set) function, that should call a
%   load_<data_set>_raw function. Additionally, in are subdirectories for
%   different experiments where the tensors should be stored when output
%   from this function.
%
%   Joshua Pickard (jpic@umich.edu)
%
% Sample Arugments:
%   data_set = "CWR"; 
%   experiment_name = "epsilon_bounds/upper_bounds/1/logspaced/";
%   feature_type = "TS";
%   array_idx = 2;
% These arguments correspond to the experiment data stored at:
%   Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\CWR\epsilons_T_5
function driver_tensorize(data_set, experiment_name, feature_type, array_idx)
%%
    disp(data_set);
    disp(experiment_name);
    disp(array_idx);
    
    num_windows = array_idx;

    % Add paths
    %add_paths();
    
    % Load in data from files
    [data_bandpass, params, ~, filtered] = load_data_raw(data_set);
    data_path = load_data_path(data_set);
    disp(data_path);
    disp("Data loaded");
    if filtered
        disp("Loaded data has already been filtered");
        disp("Job will continue");
    else
        disp("Loaded data has not been filtered");
        disp("Job will continue");
    end
    
    %% Compute Epsilon Values
    if ismember('DOD_Epsilon', params.keys)
        eps = params('DOD_Epsilon');
        epsilons = [eps; eps];
    else
        eps = logspace(-10, -3, 20);
        upper_1 = eps(15);
        upper_2 = eps(16);
        upper_3 = eps(17);
        upper_4 = eps(17);
        upper_5 = eps(18);
        upper_6 = eps(18);
        upper_7 = eps(18);
        upper_8 = eps(18);
        lower = 10e-10;
        num_epsilons = 40;
        epsilons = exp([linspace(log(lower), log(upper_1), num_epsilons);
                        linspace(log(lower), log(upper_2), num_epsilons)
                        linspace(log(lower), log(upper_3), num_epsilons);
                        linspace(log(lower), log(upper_4), num_epsilons);
                        linspace(log(lower), log(upper_5), num_epsilons);
                        linspace(log(lower), log(upper_6), num_epsilons);
                        linspace(log(lower), log(upper_7), num_epsilons);
                        linspace(log(lower), log(upper_8), num_epsilons);
                    ]);

        %eps = logspace(-4, 0, 50);
        %epsilons = [eps; eps];
    end
    disp("Epsilons:");
    %disp("    eps = logspace(-4, 0, 75);");
    disp(epsilons);

    % Construct Tensors
    % Generally, the tensor format will be:
    % <signal>x<window>x<epsilon>x<features>
    % The function should have the following parameters passed:
    % Data, number of windows, number of periods

    % These tensors will be saved to a map that has a key: string(num_windows)
    % and a value that is the data table. Let's try windows 1-15:30-2 periods
    % per window
    %% Tensorization
    num_periods = 0;
    %for feature_type=["TS"]
        %tensors = containers.Map();
        %for num_windows=2:10
    disp(string(num_windows));
    tensors = construct_tensors(data_bandpass, ...
        params, feature_type, num_periods, num_windows, epsilons, strcmp(data_set, experiment_name));
    mkdir(data_path + experiment_name)
    save(char(data_path + experiment_name + "/tensors_" + string(num_windows) + ".mat"), 'tensors', '-v7.3');
    %end
    %end
    disp("Job complete")
end