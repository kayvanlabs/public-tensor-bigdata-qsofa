function [data, params] = load_DOD(quake, noise)
    data = table([],[],[],[],'VariableNames',{'Ids','Labels','Tensors','Non-Tensor-Features'});
    for i=1:1000
        data = [data; {i,1,tensor(quake{i,1}),[]}];
        %data{i,1} = i;
        %data{i,2} = 1;
        %data{i,3} = tensor(quake{i,1});
    end
    for i=1001:2000
        data = [data; {i,0,tensor(noise{i-1000,1}),[]}];
        %data{i,1} = i;
        %data{i,2} = 1;
        %data{i,3} = tensor(noise{i,1});
    end
    params = containers.Map;
    params('Feature Mode') = 4;
    params('CP ALS Rank') = 5;
    params('HOSVD Modes') = [0];
    params('HOSVD Errors') = [0];
    params('Non-Tensor-Features') = false;
end