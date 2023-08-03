function add_paths()
    % Add to path functions for feature extraction
    if ispc
        disp("Running on PC");
        addpath(genpath('./'));
    else
        disp("Running on Cluster");
        addpath(genpath('./'));
    end
    disp("Add paths complete");
    disp(" ");
end