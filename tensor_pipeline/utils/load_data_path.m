function data_path=load_data_path(dataset)
    if strcmp(dataset, "CWR")
        if ispc
            data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\CWR\';
        else
            data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/CWR/';
        end
    elseif strcmp(dataset, "PTB")
        if ispc
            data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\PTB\';
        else
            data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/PTB/';
        end
    elseif strcmp(dataset, "EMG")
        if ispc
            data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\EMG\';
        else
            data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/EMG/';
        end
    elseif strcmpi(dataset, "qsofaEcg") || strcmpi(dataset, "qsofaArt") || strcmpi(dataset, "qsofaHrv") 
        if ispc
            data_path = 'Z:/Projects/Tensor_Sepsis/Data/Processed/Non-Specific/Modeling/qSOFA/';
        else
            data_path = '/nfs/turbo/med-kayvan-lab/Projects/Tensor_Sepsis/Data/Processed/Non-Specific/Modeling/qSOFA/';
        end
    end
end