function data_path=load_data_path(dataset)
    if strcmpi(dataset, "qsofaEcg") || strcmpi(dataset, "qsofaArt")
        data_path = './';  % Replace with your own path
    end
end