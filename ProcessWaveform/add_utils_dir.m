function add_utils_dir()
% DESCRIPTION
% Adds the DOD 'utils' directory to the working path
    if ispc
        addpath(genpath('Z:/Projects/Tensor_Sepsis/Code/oialge/tensor-bigdata/DOD/matlab/utils/'));
    else
        addpath(genpath('/nfs/turbo/med-kayvan-lab/Projects/Tensor_Sepsis/Code/oialge/tensor-bigdata/DOD/matlab/utils/'));
    end
end