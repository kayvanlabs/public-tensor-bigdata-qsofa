function add_paths()
    % Add to path functions for feature extraction
    if ispc
        disp("Running on PC");
        %addpath(genpath('Z:\Projects\DoD_Multimodal\Code\Larry\DOD\matlab'));
        addpath(genpath('Z:/Projects/Tensor_Sepsis/Code/oialge/tensor-bigdata/DOD/'));
    else
        disp("Running on Cluster");
        %addpath(genpath('/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Larry/DOD/matlab'));
        addpath(genpath('/nfs/turbo/med-kayvan-lab/Projects/Tensor_Sepsis/Code/oialge/tensor-bigdata/DOD/'));
    end
    disp("Add paths complete");
    disp(" ");
end